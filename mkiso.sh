#!/bin/sh -e

KERNEL_FILE=${1:?}
LIMINE_DIR=${2:?}
ISO_DIR=${3:?}
OUTPUT_FILE=${4:?}
LIMINE_BIN_DIR=${5:?}
LIMINE_INSTALL_BINARY=${6:?}

log()       { printf "%b%s: %s%b" "$3" "$1" "$2" "\033[0m\n"; }
log_fatal() { log "FATAL" "$1" "\033[1;38;5;196m"; exit 1; }

exit_missing() { log_fatal "$1 must be installed"; }

which xorriso > /dev/null || exit_missing xorriso

[ -e "$KERNEL_FILE" ] || log_fatal "Kernel file $KERNEL_FILE doesn't exist"
[ -f "$KERNEL_FILE" ] || log_fatal "Kernel file $KERNEL_FILE isn't a regular file"

[ -e "$LIMINE_DIR" ] || log_fatal "Limine config directory $LIMINE_DIR doesn't exist"
[ -d "$LIMINE_DIR" ] || log_fatal "Limine config directory $LIMINE_DIR isn't a directory"

[ -e "$LIMINE_BIN_DIR" ] || log_fatal "Limine binary directory $LIMINE_BIN_DIR doesn't exist"
[ -d "$LIMINE_BIN_DIR" ] || log_fatal "Limine binary directory $LIMINE_BIN_DIR isn't a directory"

[ -e "$LIMINE_BIN_DIR/limine-eltorito-efi.bin" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine-eltorito-efi.bin doesn't exist"
[ -f "$LIMINE_BIN_DIR/limine-eltorito-efi.bin" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine-eltorito-efi.bin isn't a regular file"

[ -e "$LIMINE_BIN_DIR/limine-cd.bin" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine-cd.bin doesn't exist"
[ -f "$LIMINE_BIN_DIR/limine-cd.bin" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine-cd.bin isn't a regular file"

[ -e "$LIMINE_BIN_DIR/limine.sys" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine.sys doesn't exist"
[ -f "$LIMINE_BIN_DIR/limine.sys" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/limine.sys isn't a regular file"

[ -e "$LIMINE_BIN_DIR/$LIMINE_INSTALL_BINARY" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/$LIMINE_INSTALL_BINARY doesn't exist"
[ -f "$LIMINE_BIN_DIR/$LIMINE_INSTALL_BINARY" ] || log_fatal "Limine binary $LIMINE_BIN_DIR/$LIMINE_INSTALL_BINARY isn't a regular file"

rm -rf "$ISO_DIR"
rm -f  "$OUTPUT_FILE"

mkdir -p "$ISO_DIR"
mkdir -p "$ISO_DIR/boot"

cp "$KERNEL_FILE" "$ISO_DIR/boot/kernel"
cp -r "$LIMINE_DIR/"* "$ISO_DIR/boot"
cp "$LIMINE_BIN_DIR/limine.sys" "$ISO_DIR/boot"
cp "$LIMINE_BIN_DIR/limine-eltorito-efi.bin" "$ISO_DIR"
cp "$LIMINE_BIN_DIR/limine-cd.bin" "$ISO_DIR"
xorriso -as mkisofs -b "limine-cd.bin" \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        --efi-boot "limine-eltorito-efi.bin" \
        -efi-boot-part --efi-boot-image --protective-msdos-label \
        "$ISO_DIR" -o "$OUTPUT_FILE"

"$LIMINE_BIN_DIR/$LIMINE_INSTALL_BINARY" "$OUTPUT_FILE"
rm -rf "$ISO_DIR"
