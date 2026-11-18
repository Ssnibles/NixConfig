# PipeWire audio, including the AutoEq equaliser sinks. The curve follows the
# output device automatically; see docs/wiki/media-audio.md.
_: {
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # AutoEq parametric EQ curves. PipeWire's param_eq filter reads this
      # format, preamp included, so no extra packages are needed. Replace the
      # text to change a curve; every value comes from the AutoEq results.
      #
      # `match` is tested against the output device, which is why the Aria 2
      # profile matches the Dawn Pro DAC rather than the IEMs themselves.
      profiles = import ./pipewire/_profiles.nix { inherit pkgs; };

      names = lib.attrNames profiles;
      sinks = lib.concatStringsSep "|" (map (name: profiles.${name}.sink) names);

      # One virtual sink per profile. The playback side is passive, so
      # WirePlumber links it to whichever device is the default output.
      mkChain = profile: {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = profile.description;
          "media.name" = profile.description;
          "filter.graph".nodes = [
            {
              type = "builtin";
              name = "eq";
              label = "param_eq";
              config.filename = profile.curve;
            }
          ];
          "audio.channels" = 2;
          "audio.position" = [
            "FL"
            "FR"
          ];
          "capture.props" = {
            "node.name" = profile.sink;
            "media.class" = "Audio/Sink";
          };
          "playback.props" = {
            "node.name" = "${profile.sink}.out";
            "node.passive" = true;
          };
        };
      };

      profileLua = lib.concatMapStrings (profile: ''
        { sink = "${profile.sink}", match = { ${
          lib.concatMapStrings (needle: ''"${needle}", '') profile.match
        } } },
      '') (lib.attrValues profiles);

      # Picks the equaliser sink that matches the best physical output. The
      # metadata key acts as a latch so a manual choice is not overridden.
      autoEqLua = lib.replaceStrings [ "@PROFILES@" ] [ profileLua ] (
        builtins.readFile ./pipewire/auto-eq.lua.in
      );

      eqCases = lib.concatMapStrings (name: ''
        ${name})
            current=$("$pactl" get-default-sink)
            set_latch manual
            switch_to ${profiles.${name}.sink} "$current"
            ;;
      '') names;
    in
    {
      environment.systemPackages = with pkgs; [
        pavucontrol

        (writeShellScriptBin "pipewire-eq" ''
          set -eu

          pactl=${pulseaudio}/bin/pactl
          pwlink=${pipewire}/bin/pw-link
          pwmetadata=${pipewire}/bin/pw-metadata
          latch=default.auto-eq

          usage() {
            echo "usage: pipewire-eq <profile|on|off|status>" >&2
            echo "  on:       pick the curve for the current output automatically" >&2
            echo "  off:      bypass the equaliser" >&2
            echo "  status:   print the default sink and the auto state" >&2
            echo "  profiles: ${lib.concatStringsSep ", " names} (force one curve)" >&2
            exit 2
          }

          set_latch() {
            "$pwmetadata" -n default 0 "$latch" "$1" >/dev/null 2>&1
          }

          clear_latch() {
            "$pwmetadata" -n default -d "$latch" >/dev/null 2>&1 || true
          }

          latched() {
            "$pwmetadata" -n default 2>/dev/null | grep -q "$latch"
          }

          # The chain is linked to the device it feeds, which is where audio
          # has to go back to when the equaliser is bypassed.
          fed_device() {
            "$pwlink" -l | awk '
              /^(${sinks})\.out:output_FL$/ {
                getline
                sub(/^ *\|-> /, "")
                sub(/:playback.*/, "")
                print
                exit
              }
            '
          }

          # Volume is applied twice, once by the sink in front of the device
          # and once by the device itself. Both use the same curve, so the
          # product is the loudness the user hears.
          vol() {
            "$pactl" get-sink-volume "$1" 2>/dev/null | awk '
              {
                for (i = 1; i <= NF; i++)
                  if ($i ~ /%$/) { sub (/%/, "", $i); printf "%.6f", $i / 100; exit }
              }
            '
          }

          percent() {
            a=$(vol "$1")
            [ -n "$a" ] || return 1
            awk -v a="$a" 'BEGIN { printf "%.2f", a * 100 }'
          }

          setvol() {
            [ -n "$2" ] && "$pactl" set-sink-volume "$1" "$2%" >/dev/null 2>&1
            return 0
          }

          # Bluetooth volume belongs to the headset, so leave it alone.
          unity() {
            [ -n "$1" ] || return 0
            case "$1" in
            bluez_output.*) return 0 ;;
            esac
            setvol "$1" 100
          }

          # Move to another sink without changing the loudness. The sink in the
          # path holds the volume, so carry it over and leave the device it
          # feeds at unity. Bluetooth devices keep their own volume.
          switch_to() {
            target=$1
            if [ "$#" -ge 2 ]; then current=$2; else current=$("$pactl" get-default-sink); fi
            device=$(fed_device)
            [ -n "$device" ] || device=$current
            volume=$(percent "$current") || volume=

            # A rescan may already be in flight from the metadata change that
            # came before this, so re-assert the target once it has settled.
            "$pactl" set-default-sink "$target"
            sleep 0.2
            if [ "$("$pactl" get-default-sink)" != "$target" ]; then
              "$pactl" set-default-sink "$target"
            fi

            setvol "$target" "$volume"
            case "$target" in
            ${sinks})
              case "$device" in
              ${sinks}) ;;
              *) unity "$device" ;;
              esac
              ;;
            esac
          }

          if [ "$#" -ne 1 ]; then
            usage
          fi

          case "$1" in
          ${eqCases}
            on)
              clear_latch
              sleep 0.3
              switch_to "$("$pactl" get-default-sink)"
              ;;
            off)
              device=$(fed_device)
              if [ -z "$device" ]; then
                device=$("$pactl" list short sinks |
                  awk -v ours="^(${sinks})$" '$2 !~ ours { print $2; exit }')
              fi
              if [ -z "$device" ]; then
                echo "pipewire-eq: no output device to fall back to" >&2
                exit 1
              fi
              current=$("$pactl" get-default-sink)
              set_latch off
              switch_to "$device" "$current"
              ;;
            status)
              echo "default: $("$pactl" get-default-sink)"
              if latched; then
                echo "auto: off"
              else
                echo "auto: on"
              fi
              ;;
            *)
              usage
              ;;
          esac
        '')
      ];

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        extraConfig.pipewire."99-eq" = {
          "context.modules" = map mkChain (lib.attrValues profiles);
        };

        wireplumber.extraScripts."auto-eq.lua" = autoEqLua;
        wireplumber.extraConfig."99-auto-eq" = {
          "wireplumber.components" = [
            {
              name = "auto-eq.lua";
              type = "script/lua";
              provides = "auto-eq";
            }
          ];
          "wireplumber.profiles".main."auto-eq" = "required";
        };
      };
    };
}
