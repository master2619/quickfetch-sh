#!/bin/sh

# Helper functions

get_os_info() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$PRETTY_NAME"
    else
        echo "Unknown"
    fi
}

get_kernel_info() {
    uname -r
}

get_arch_info() {
    uname -m
}

get_cpu_info() {
    cpu_name=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[ \t]*//')
    cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    echo "$cpu_name ($cpu_cores cores)"
}

get_memory_info() {
    free -h | awk '/^Mem:/ {print $3 " / " $2}'
}

get_swap_info() {
    free -h | awk '/^Swap:/ {print $3 " / " $2}'
}

get_disk_usage_info() {
    df -h --output=source,used,size | grep '^/dev/' | grep -v '/snap'
}

get_battery_info() {
    if command -v upower >/dev/null 2>&1; then
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage" | awk '{print $2}' | tr '\n' ' ' | sed 's/ $//'
    else
        echo "No Battery"
    fi
}

get_gpu_info() {
    if command -v lspci >/dev/null 2>&1; then
        lspci | grep -E "VGA|3D" | cut -d: -f3 | sed 's/^[ \t]*//'
    else
        echo "Unknown"
    fi
}

get_local_ip_info() {
    ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1
}

get_uptime_info() {
    uptime -p | sed 's/up //'
}

get_hostname_info() {
    hostname
}

get_user_info() {
    whoami
}

get_locale_info() {
    echo "$LANG"
}

get_package_manager_info() {
    managers="dpkg apt rpm pacman dnf snap flatpak"
    for mgr in $managers; do
        case $mgr in
            dpkg) count=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l);;
            apt) count=$(apt list --installed 2>/dev/null | wc -l);;
            rpm) count=$(rpm -qa 2>/dev/null | wc -l);;
            pacman) count=$(pacman -Q 2>/dev/null | wc -l);;
            dnf) count=$(dnf list installed 2>/dev/null | wc -l);;
            snap) count=$(snap list 2>/dev/null | wc -l);;
            flatpak) count=$(flatpak list 2>/dev/null | wc -l);;
        esac
        if [ "$count" -gt 0 ]; then
            echo "$mgr: $count packages"
        fi
    done
}

get_resolution() {
    if command -v xrandr >/dev/null 2>&1; then
        xrandr | grep '*' | awk '{print $1}'
    elif command -v xdpyinfo >/dev/null 2>&1; then
        xdpyinfo | grep dimensions | awk '{print $2}'
    else
        echo "Unknown"
    fi
}

get_desktop_environment() {
    echo "${DESKTOP_SESSION:-Unknown}" | tr '[:lower:]' '[:upper:]'
}

get_window_manager() {
    echo "${XDG_SESSION_TYPE:-Unknown}"
}

get_window_manager_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.wm.preferences theme | tr -d "'"
    else
        echo "Unknown"
    fi
}

get_gtk_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'"
    else
        echo "Unknown"
    fi
}

get_icon_theme() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.interface icon-theme | tr -d "'"
    else
        echo "Unknown"
    fi
}

get_terminal() {
    echo "${TERM:-Unknown}"
}

get_terminal_font() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.interface monospace-font-name | tr -d "'"
    else
        echo "Unknown"
    fi
}

get_system_font() {
    if command -v gsettings >/dev/null 2>&1; then
        gsettings get org.gnome.desktop.interface font-name | tr -d "'"
    else
        echo "Unknown"
    fi
}

print_color_strip() {
    printf "\033[91m█\033[92m█\033[93m█\033[94m█\033[95m█\033[96m█\033[97m█\033[91m█\033[92m█\033[93m█\033[94m█\033[95m█\033[96m█\033[97m█\033[0m\n"
}

get_distro_logo() {
    os=$(get_os_info)
    if echo "$os" | grep -iq "zorin"; then
        printf '
██████████
████████████████
████████████████████
████████████████████████
████████████████████████
████████████████████████
████████████████████████
████████████████████
████████████████
██████████\n'
    else
        echo "Unsupported distro for artwork display"
    fi
}

# Main execution
experimental=0
if [ "$1" = "--experimental" ]; then
    experimental=1
fi

user=$(get_user_info)
hostname=$(get_hostname_info)
os_info=$(get_os_info)
kernel=$(get_kernel_info)
architecture=$(get_arch_info)
cpu_info=$(get_cpu_info)
gpu_info=$(get_gpu_info)
memory_info=$(get_memory_info)
swap_info=$(get_swap_info)
uptime=$(get_uptime_info)
resolution=$(get_resolution)
desktop_environment=$(get_desktop_environment)
window_manager=$(get_window_manager)
window_manager_theme=$(get_window_manager_theme)
gtk_theme=$(get_gtk_theme)
icon_theme=$(get_icon_theme)
terminal=$(get_terminal)
terminal_font=$(get_terminal_font)
system_font=$(get_system_font)
local_ip=$(get_local_ip_info)
battery_info=$(get_battery_info)
locale_info=$(get_locale_info)

if [ $experimental -eq 1 ]; then
    logo=$(get_distro_logo)
    if [ "$logo" != "Unsupported distro for artwork display" ]; then
        printf "%s\n" "$logo"
    fi
fi

printf "User: %s@%s\n" "$user" "$hostname"
printf "OS: %s\n" "$os_info"
printf "Kernel: %s\n" "$kernel"
printf "Architecture: %s\n" "$architecture"
printf "CPU: %s\n" "$cpu_info"
printf "GPU: %s\n" "$gpu_info"
printf "Memory: %s\n" "$memory_info"
printf "Swap: %s\n" "$swap_info"
printf "Uptime: %s\n" "$uptime"
printf "Resolution: %s\n" "$resolution"
printf "DE: %s\n" "$desktop_environment"
printf "WM: %s\n" "$window_manager"
printf "WM Theme: %s\n" "$window_manager_theme"
printf "Theme: %s\n" "$gtk_theme"
printf "Icons: %s\n" "$icon_theme"
printf "Terminal: %s\n" "$terminal"
printf "Terminal Font: %s\n" "$terminal_font"
printf "System Font: %s\n" "$system_font"
get_disk_usage_info
printf "Local IP: %s\n" "$local_ip"
printf "Battery: %s\n" "$battery_info"
printf "Locale: %s\n" "$locale_info"
get_package_manager_info

print_color_strip
