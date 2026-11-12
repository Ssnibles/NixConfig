# PipeWire audio, including the AutoEq equaliser sinks. The curve follows the
# output device automatically; see docs/wiki/media-audio.md.
{ ... }:
{
  nixos.modules.shared =
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
      profiles = {
        # https://github.com/jaakkopasanen/AutoEq/tree/master/results/Harpo/in-ear/Moondrop%20Aria%202
        aria2 = {
          sink = "eq_aria2";
          description = "Aria 2 EQ";
          match = [
            "moondrop"
            "dawn pro"
          ];
          curve = pkgs.writeText "moondrop-aria2-parametric-eq.txt" ''
            Preamp: -4.4 dB
            Filter 1: ON LSC Fc 105 Hz Gain 1.7 dB Q 0.70
            Filter 2: ON PK Fc 159 Hz Gain -3.2 dB Q 0.64
            Filter 3: ON PK Fc 7000 Hz Gain 3.5 dB Q 1.20
            Filter 4: ON PK Fc 773 Hz Gain 2.4 dB Q 0.93
            Filter 5: ON PK Fc 1802 Hz Gain -1.2 dB Q 0.91
            Filter 6: ON HSC Fc 10000 Hz Gain -1.0 dB Q 0.70
            Filter 7: ON PK Fc 4551 Hz Gain -1.5 dB Q 4.73
            Filter 8: ON PK Fc 6036 Hz Gain 1.9 dB Q 5.44
            Filter 9: ON PK Fc 7146 Hz Gain -0.9 dB Q 6.00
            Filter 10: ON PK Fc 3343 Hz Gain 0.6 dB Q 4.19
          '';
        };

        # https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990/over-ear/Sennheiser%20HD%20450BT
        hd450bt = {
          sink = "eq_hd450bt";
          description = "HD 450BT EQ";
          match = [
            "hd 450"
            "450bt"
          ];
          curve = pkgs.writeText "sennheiser-hd450bt-parametric-eq.txt" ''
            Preamp: -6.4 dB
            Filter 1: ON LSC Fc 105 Hz Gain -2.7 dB Q 0.70
            Filter 2: ON PK Fc 2417 Hz Gain -4.2 dB Q 0.56
            Filter 3: ON PK Fc 3855 Hz Gain 8.3 dB Q 1.65
            Filter 4: ON PK Fc 151 Hz Gain -3.0 dB Q 1.14
            Filter 5: ON PK Fc 6571 Hz Gain 3.5 dB Q 1.15
            Filter 6: ON HSC Fc 10000 Hz Gain 5.6 dB Q 0.70
            Filter 7: ON PK Fc 8215 Hz Gain -2.8 dB Q 4.27
            Filter 8: ON PK Fc 374 Hz Gain 0.9 dB Q 2.79
            Filter 9: ON PK Fc 656 Hz Gain -0.6 dB Q 2.31
            Filter 10: ON PK Fc 41 Hz Gain -0.2 dB Q 1.75
          '';
        };
      };

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
      autoEqLua = ''
        log = Log.open_topic ("s-auto-eq")

        local nutils = require ("node-utils")

        local profiles = {
        ${profileLua}}

        local latch_key = "default.auto-eq"

        local function is_eq_sink (name)
          for _, profile in ipairs (profiles) do
            if profile.sink == name then
              return true
            end
          end
          return false
        end

        local function matches (profile, props)
          local fields = {
            props ["node.name"],
            props ["node.description"],
            props ["device.name"],
            props ["device.description"],
          }
          for _, field in ipairs (fields) do
            if field then
              local value = string.lower (tostring (field))
              for _, needle in ipairs (profile.match) do
                if string.find (value, needle, 1, true) then
                  return true
                end
              end
            end
          end
          return false
        end

        local function get_metadata (source)
          local om = source:call ("get-object-manager", "metadata")
          return om and om:lookup { Constraint { "metadata.name", "=", "default" } }
        end

        -- Wake the default-nodes policy when the latch is set or cleared.
        SimpleEventHook {
          name = "auto-eq/rescan-on-latch",
          interests = {
            EventInterest {
              Constraint { "event.type", "=", "metadata-changed" },
              Constraint { "metadata.name", "=", "default" },
            },
          },
          execute = function (event)
            local key = event:get_properties ()["event.subject.key"]
            if key == latch_key or key == nil then
              event:get_source ():call ("schedule-rescan", "default-nodes")
            end
          end,
        }:register ()

        SimpleEventHook {
          name = "auto-eq/select-eq-sink",
          after = {
            "default-nodes/find-best-default-node",
            "default-nodes/find-selected-default-node",
            "default-nodes/find-stored-default-node",
          },
          before = { "default-nodes/apply-default-node" },
          interests = {
            EventInterest { Constraint { "event.type", "=", "select-default-node" } },
          },
          execute = function (event)
            if event:get_properties ()["default-node.type"] ~= "audio.sink" then
              return
            end

            local source = event:get_source ()
            local metadata = get_metadata (source)
            if metadata and metadata:find (0, latch_key) then
              return
            end

            local available = event:get_data ("available-nodes")
            available = available and available:parse ()
            if not available then
              return
            end

            local best, best_prio
            for _, node in ipairs (available) do
              local name = node ["node.name"]
              if name and not is_eq_sink (name) and node ["device.id"] then
                local prio = nutils.get_session_priority (node)
                if not best_prio or prio > best_prio then
                  best, best_prio = node, prio
                end
              end
            end
            if not best then
              return
            end

            for _, profile in ipairs (profiles) do
              if matches (profile, best) then
                event:set_data ("selected-node", profile.sink)
                event:set_data ("selected-node-priority", 100000)
                return
              end
            end

            event:set_data ("selected-node", best ["node.name"])
            event:set_data ("selected-node-priority", best_prio)
          end,
        }:register ()
      '';

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
