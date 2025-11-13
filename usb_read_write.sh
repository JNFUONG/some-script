#!/bin/bash

usage() {
    echo "用法: $0 <设备名> [测试大小(MB)]"
    echo "示例:"
    echo "  $0 sdb           # 测试sdb设备，默认500MB"
    echo "  $0 sdc 200       # 测试sdc设备，200MB文件"
    echo ""
    echo "当前存储设备:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "sd[b-z]"
}

# 检查参数
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

usb_device="$1"
test_size="${2:-500}"  # 默认500MB

# 设备验证
if [ ! -b "/dev/$usb_device" ]; then
    echo "错误: 设备 /dev/$usb_device 不存在"
    usage
    exit 1
fi

echo "=== USB速度测试: /dev/$usb_device (${test_size}MB) ==="

# 挂载设备
mount_point="/mnt/usb_test_$$"
mkdir -p "$mount_point"

if ! mount "/dev/${usb_device}1" "$mount_point" 2>/dev/null && \
   ! mount "/dev/$usb_device" "$mount_point" 2>/dev/null; then
    echo "错误: 挂载失败"
    rmdir "$mount_point"
    exit 1
fi

# 测试函数
run_test() {
    local test_file="$mount_point/test.bin"
    
    # 清缓存+写入
    sync && echo 3 > /proc/sys/vm/drop_caches
    echo "清缓存后，写入测试:"
    dd if=/dev/zero of="$test_file" bs=1M count=$test_size oflag=direct status=progress 2>&1
    
    # 清缓存+读取
    sync && echo 3 > /proc/sys/vm/drop_caches
    echo "清缓存后，读取测试:"
    dd if="$test_file" of=/dev/null bs=1M count=$test_size iflag=direct status=progress 2>&1
    
    rm -f "$test_file"
}

# 执行测试
run_test

# 清理
umount "$mount_point" 2>/dev/null
rmdir "$mount_point" 2>/dev/null

echo "测试完成!"
