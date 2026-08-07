package main

import (
	"bytes"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var reloadScript = []byte(`<script>
new EventSource("/events").onmessage = function(e) {
    if (e.data === "reload") location.reload();
};
</script></body>`)

var ignoredDirs = map[string]bool{
	".git":         true,
	"node_modules": true,
	".direnv":      true,
	"dist":         true,
	"build":        true,
}

func getLatestModTime(dir string) time.Time {
	var maxTime time.Time
	_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if info.IsDir() {
			if ignoredDirs[info.Name()] && path != dir {
				return filepath.SkipDir
			}
			return nil
		}
		if info.ModTime().After(maxTime) {
			maxTime = info.ModTime()
		}
		return nil
	})
	return maxTime
}

func main() {
	port := flag.String("port", "8080", "Port to serve on")
	host := flag.String("host", "localhost", "Host address to bind to")
	dir := flag.String("dir", "", "Directory path to serve")
	filePath := flag.String("file", "", "Specific HTML file to preview directly")
	noOpen := flag.Bool("no-open", false, "Disable opening default browser automatically")
	pollMs := flag.Int("interval", 300, "File check interval in milliseconds")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options] [file-or-directory-path]\n\nOptions:\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	// Determine input path from flags or positional argument
	inputPath := ""
	if *filePath != "" {
		inputPath = *filePath
	} else if *dir != "" {
		inputPath = *dir
	} else if flag.NArg() > 0 {
		inputPath = flag.Arg(0)
	} else {
		inputPath = "."
	}

	info, err := os.Stat(inputPath)
	if err != nil {
		log.Fatalf("Error: path '%s' does not exist", inputPath)
	}

	var targetFile string
	var absDir string

	if info.IsDir() {
		absDir, err = filepath.Abs(inputPath)
		if err != nil {
			log.Fatalf("Invalid directory path: %v", err)
		}
	} else {
		targetFile, err = filepath.Abs(inputPath)
		if err != nil {
			log.Fatalf("Invalid file path: %v", err)
		}
		absDir = filepath.Dir(targetFile)
	}

	http.HandleFunc("/events", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Connection", "keep-alive")

		lastMod := getLatestModTime(absDir)
		ticker := time.NewTicker(time.Duration(*pollMs) * time.Millisecond)
		defer ticker.Stop()

		for {
			select {
			case <-r.Context().Done():
				return
			case <-ticker.C:
				currentMod := getLatestModTime(absDir)
				if currentMod.After(lastMod) {
					lastMod = currentMod
					fmt.Fprintf(w, "data: reload\n\n")
					if flusher, ok := w.(http.Flusher); ok {
						flusher.Flush()
					}
				}
			}
		}
	})

	fileServer := http.FileServer(http.Dir(absDir))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-cache, no-store, must-revalidate")

		reqPath := filepath.Clean(r.URL.Path)
		var servePath string

		if targetFile != "" {
			if reqPath == "/" || reqPath == "/index.html" || reqPath == "/"+filepath.Base(targetFile) {
				servePath = targetFile
			} else {
				servePath = filepath.Join(absDir, reqPath)
			}
		} else {
			servePath = filepath.Join(absDir, reqPath)
			fileInfo, err := os.Stat(servePath)
			if err == nil && fileInfo.IsDir() {
				servePath = filepath.Join(servePath, "index.html")
			}
		}

		fileInfo, err := os.Stat(servePath)

		// Disable directory browsing if index.html is missing
		if err == nil && fileInfo.IsDir() {
			http.NotFound(w, r)
			return
		}

		// Inject live reload script into HTML content
		if err == nil && !fileInfo.IsDir() && strings.HasSuffix(strings.ToLower(servePath), ".html") {
			content, err := os.ReadFile(servePath)
			if err == nil {
				w.Header().Set("Content-Type", "text/html; charset=utf-8")

				lowerContent := bytes.ToLower(content)
				idx := bytes.Index(lowerContent, []byte("</body>"))
				if idx != -1 {
					var buf bytes.Buffer
					buf.Write(content[:idx])
					buf.Write(reloadScript)
					buf.Write(content[idx+7:])
					w.Write(buf.Bytes())
				} else {
					content = append(content, reloadScript...)
					w.Write(content)
				}
				return
			}
		}

		fileServer.ServeHTTP(w, r)
	})

	url := fmt.Sprintf("http://%s:%s", *host, *port)
	if targetFile != "" {
		fmt.Printf("Serving target file: %s\nURL: %s\n", targetFile, url)
	} else {
		fmt.Printf("Serving folder: %s\nURL: %s\n", absDir, url)
	}

	if !*noOpen {
		go func() {
			time.Sleep(100 * time.Millisecond)
			_ = exec.Command("xdg-open", url).Start()
		}()
	}

	log.Fatal(http.ListenAndServe(*host+":"+*port, nil))
}
