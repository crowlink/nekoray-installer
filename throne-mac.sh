#!/bin/bash
set -euo pipefail

# Configuration
THRONE_URL="https://api.github.com/repos/throneproj/Throne/releases/latest"
THRONE_APP_NAME="Throne"
THRONE_APP_PATH="/Applications/${THRONE_APP_NAME}.app"
ARCH=$(uname -m)
TMPDIR=$(mktemp -d)
CURL_TIMEOUT=15

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Display banner
show_banner() {
  echo -e "${YELLOW}"
  cat <<EOF



████████╗██╗  ██╗██████╗  ██████╗ ███╗   ██╗███████╗
╚══██╔══╝██║  ██║██╔══██╗██╔═══██╗████╗  ██║██╔════╝
   ██║   ███████║██████╔╝██║   ██║██╔██╗ ██║█████╗
   ██║   ██╔══██║██╔══██╗██║   ██║██║╚██╗██║██╔══╝
   ██║   ██║  ██║██║  ██║╚██████╔╝██║ ╚████║███████╗
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝



EOF
  echo -e "${NC}"
  echo -e "${BLUE}$THRONE_APP_NAME Installer for macOS${NC}\n\n\n"
}

# Show main menu
show_menu() {
  echo -e "${YELLOW}Please select an option:${NC}"
  echo "1) Install Throne"
  echo "2) Backup configuration"
  echo "3) Restore configuration"
  echo "4) Uninstall"
  echo "5) Exit"
  echo
}

# Function to get app name from user
get_app_name() {
  read -rp "👉 Enter which app (Throne or oldest nekoray): " APP_NAME
  APP_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')

  if [[ "$APP_NAME" != "nekoray" && "$APP_NAME" != "throne" ]]; then
    echo -e "${RED}Invalid app name. Only 'Throne' or 'throne' allowed.${NC}"
    exit 1
  fi
}

# Install function
install_app() {
  echo -e "${BLUE}=== INSTALLATION ===${NC}\n"

  # Check if already installed
  if [ -d "$THRONE_APP_PATH" ]; then
    echo -e "${YELLOW}${THRONE_APP_NAME} is already installed at ${THRONE_APP_PATH}.${NC}"
    echo -e "${YELLOW}Please back it up and delete it if you want to reinstall.${NC}\n"
    return 0
  fi

  # Check for required commands
  for cmd in unzip curl; do
    if ! command -v $cmd &> /dev/null; then
      echo -e "${RED}Missing command: $cmd${NC}"
      echo -e "${RED}Install it with: brew install $cmd${NC}"
      exit 1
    fi
  done

  # Fetch latest release download and install
  echo -e "Fetching latest ${THRONE_APP_NAME} release..."
  DOWNLOAD_URL=$(curl --max-time $CURL_TIMEOUT -s "$THRONE_URL" \
    | grep -Eo "https.*${THRONE_APP_NAME}.*macos-${ARCH}\.zip" \
    | head -n 1)

  if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}Failed to find download URL for macOS $ARCH.${NC}"
    exit 1
  fi

  echo -e "Downloading from: $DOWNLOAD_URL"
  curl --max-time $CURL_TIMEOUT -L --progress-bar \
    -o "$TMPDIR/${THRONE_APP_NAME}.zip" "$DOWNLOAD_URL"

  echo -e "Installing..."
  unzip -q "$TMPDIR/${THRONE_APP_NAME}.zip" -d "$TMPDIR"
  mv "$TMPDIR/${THRONE_APP_NAME}/${THRONE_APP_NAME}.app" "/Applications/"

  rm -rf "$TMPDIR"

  # Done
  echo -e "\n${GREEN}✅ Done! ${THRONE_APP_NAME} has been installed to /Applications.${NC}"
  echo -e "${GREEN}You can now launch '${THRONE_APP_NAME}' from Spotlight or Launchpad.${NC}\n"
}

# Backup function
backup_config() {
  echo -e "${BLUE}=== BACKUP CONFIGURATION ===${NC}\n"

  get_app_name

  CONFIG_DIR="$HOME/Library/Preferences/$APP_NAME/config"
  BACKUP_NAME="${APP_NAME}-backup-$(date +%Y-%m-%d).zip"
  DEST_DIR="$(pwd)"

  if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Config directory does not exist: $CONFIG_DIR${NC}"
    exit 1
  fi

  if ! command -v zip &> /dev/null; then
    echo -e "${RED}Missing 'zip'. Install it with:${NC}"
    echo -e "${RED}  brew install zip${NC}"
    exit 1
  fi

  echo "📦 Compressing config ..."

  echo "Compressing config from $CONFIG_DIR..."
  (cd "$CONFIG_DIR" && zip -rq "$DEST_DIR/$BACKUP_NAME" .)

  echo -e "${GREEN}✅ Backup created:${NC}"
  echo -e "${GREEN}$DEST_DIR/$BACKUP_NAME${NC}\n"
}

# Restore function
restore_config() {
  echo -e "${BLUE}=== RESTORE CONFIGURATION ===${NC}\n"

  read -rp "Enter the path to the backup .zip file: " ZIP_FILE

  if [[ -z "$ZIP_FILE" ]]; then
    echo -e "${RED}Please provide the path to the backup .zip file.${NC}"
    exit 1
  fi

  if [[ ! -f "$ZIP_FILE" ]]; then
    echo -e "${RED}File not found: $ZIP_FILE${NC}"
    exit 1
  fi

  get_app_name

  RESTORE_DIR="$HOME/Library/Preferences/$APP_NAME/config"

  if ! command -v unzip &> /dev/null; then
    echo -e "${RED}'unzip' is required. Install it with:${NC}"
    echo -e "${RED}  brew install unzip${NC}"
    exit 1
  fi

  if [[ -d "$RESTORE_DIR" ]]; then
    echo "Removing existing config: $RESTORE_DIR"
    rm -rf "$RESTORE_DIR"
  fi

  mkdir -p "$RESTORE_DIR"

  echo "📦 Restoring backup to: $RESTORE_DIR"
  unzip -q "$ZIP_FILE" -d "$RESTORE_DIR"

  echo -e "${GREEN}✅ Restore complete!${NC}\n"
}

# Uninstall function
uninstall_app() {
  echo -e "${BLUE}=== UNINSTALL ===${NC}\n"

  get_app_name

  APP_PREFS_DIR="$HOME/Library/Preferences/$APP_NAME"
  APP_BUNDLE="/Applications/$APP_NAME.app"

  echo -e "\nUninstalling $APP_NAME..."

  # Remove app preferences folder
  if [ -d "$APP_PREFS_DIR" ]; then
    echo "Removing preferences: $APP_PREFS_DIR"
    sudo rm -rvf "$APP_PREFS_DIR"
  else
    echo "No preferences folder found at: $APP_PREFS_DIR"
  fi

  # Remove application bundle
  if [ -d "$APP_BUNDLE" ]; then
    echo "Removing app bundle: $APP_BUNDLE"
    sudo rm -rvf "$APP_BUNDLE"
  else
    echo "No app found at: $APP_BUNDLE"
  fi

  echo -e "\n${GREEN}✅ $APP_NAME has been successfully uninstalled.${NC}\n"
}

# Main function
main() {
  show_banner

  while true; do
    show_menu
    read -rp "Enter your choice (1-5): " choice
    echo

    case $choice in
      1)
        install_app
        ;;
      2)
        backup_config
        ;;
      3)
        restore_config
        ;;
      4)
        uninstall_app
        ;;
      5)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid choice. Please select 1-5.${NC}\n"
        ;;
    esac

    read -rp "Press Enter to continue..."
    echo
  done
}

# Cleanup on exit
trap 'rm -rf "$TMPDIR"' EXIT

# Run main function
main
