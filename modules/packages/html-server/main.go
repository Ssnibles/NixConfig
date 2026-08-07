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

// Script injected into HTML to establish live-reload SSE connection
var reloadScript = []byte(`<script>
new EventSource("/events").onmessage = function(e) {
    if (e.data === "reload") location.reload();
};
</script></body>`)

// Get latest modification timestamp across all files in directory
func getLatestModTime(dir string) time.Time {
	var maxTime time.Time
	filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() {
			if info.ModTime().After(maxTime) {
				maxTime = info.ModTime()
			}
		}
		return nil
	})
	return maxTime
}

func main() {
	port := flag.String("port", "8080", "Port to serve on")
	dir := flag.String("dir", ".", "Directory path to serve")
	flag.Parse()

	absDir, err := filepath.Abs(*dir)
	if err != nil {
		log.Fatal(err)
	}

	// Server-Sent Events endpoint to stream reload triggers
	http.HandleFunc("/events", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Connection", "keep-alive")

		lastMod := getLatestModTime(absDir)
		ticker := time.NewTicker(300 * time.Millisecond)
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
					w.(http.Flusher).Flush()
				}
			}
		}
	})

	// Serve static files (HTML, CSS, JS) and inject client-side refresh code
	fileServer := http.FileServer(http.Dir(absDir))
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		path := filepath.Join(absDir, filepath.Clean(r.URL.Path))
		info, err := os.Stat(path)
		if err == nil && info.IsDir() {
			path = filepath.Join(path, "index.html")
			info, err = os.Stat(path)
		}

		if err == nil && !info.IsDir() && strings.HasSuffix(path, ".html") {
			content, err := os.ReadFile(path)
			if err == nil {
				w.Header().Set("Content-Type", "text/html; charset=utf-8")
				if bytes.Contains(content, []byte("</body>")) {
					content = bytes.Replace(content, []byte("</body>"), reloadScript, 1)
				} else {
					content = append(content, reloadScript...)
				}
				w.Write(content)
				return
			}
		}

		fileServer.ServeHTTP(w, r)
	})

	url := fmt.Sprintf("http://localhost:%s", *port)
	fmt.Printf("Serving directory %s at %s\n", absDir, url)

	// Launch default Linux web browser via xdg-open
	go func() {
		time.Sleep(100 * time.Millisecond)
		exec.Command("xdg-open", url).Start()
	}()

	log.Fatal(http.ListenAndServe(":"+*port, nil))
}
