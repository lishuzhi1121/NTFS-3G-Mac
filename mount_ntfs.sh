#!/bin/bash

# 电脑开机密码
PASS_WORD="你电脑的开机密码"
# echo $PASS_WORD
# 获取移动硬盘挂载点 /dev/disk4 (external, physical)
echo "开始获取移动硬盘挂载点..."
all_disks=`diskutil list`
external_str=`echo $all_disks |grep -E "(/dev/disk\d+\s\(external, physical\))" -o`
# echo ${external_str}
# 判断是否挂载了移动硬盘
if [ -z "$external_str" ]
then
	# 没有插入移动硬盘
    echo "未获取到移动硬盘挂载点, 请插入移动硬盘后重试!!!"
    exit 1
fi

# 空格(external左边的所有字符,即为挂载点 /dev/disk4
ext_point=${external_str% (external*}
echo "移动硬盘挂载点获取成功: "$ext_point

echo "---------------------------------------------"

echo "开始获取NTFS分区标识..."
# 获取NTFS分区标识(disk4s2) 'Microsoft Basic Data LaCie 136.3 GB disk4s2 ('
ntfs_info=`echo $all_disks |grep -E "((Microsoft|Windows_NTFS) .+ (G|T)B disk\d+s\d+)" -o`
echo $ntfs_info
if [ -z "$ntfs_info" ]
then
	# 没有NTFS格式的移动硬盘
    echo "未获取到NTFS分区信息, 请检查后重试!!!"
    exit 1
fi
ntfs_flags_str=`echo $ntfs_info |grep -E "(disk\d+s\d+)" -o`
# 以空格分割之后取第一个,则为分区标识
ntfs_flags_array=(${ntfs_flags_str// / })
ntfs_flag=${ntfs_flags_array[0]}
echo "NTFS分区标识获取成功: "$ntfs_flag
echo "---------------------------------------------"

echo "开始获取NTFS盘符名称..."
# 获取NTFS盘符名称(暂且认为 Microsoft Basic Data 或者 Windows_NTFS 是NTFS硬盘的区分标识)
disk_name_str=`echo $ntfs_info |grep -E "((Microsoft|Windows_NTFS) .+ (G|T)B $ntfs_flag)" -o`
# echo $disk_name_str
disk_name_suffix=`echo $disk_name_str |grep -E "(\s\d+\.\d+ (G|T)B disk\d+s\d+)" -o`
disk_name_part=${disk_name_str%%${disk_name_suffix}*}
# echo $disk_name_part
if [[ $disk_name_str == "Windows_NTFS"* ]]
then
	# Windows_NTFS 开头
    disk_name=${disk_name_part##*Windows_NTFS }
elif [[ $disk_name_str == "Microsoft"* ]]; then
	# Microsoft Basic Data 开头
	disk_name=${disk_name_part##*Microsoft Basic Data }
else
    echo "NTFS硬盘分区类型不支持, 获取硬盘名称失败!!!"
    exit 1
fi
echo "NTFS盘符名称获取成功: "$disk_name
echo "---------------------------------------------"

echo "开始卸载..."
# 先卸载当前挂载点
unmount_res=`echo $PASS_WORD | sudo -S diskutil unmountDisk $ext_point`
echo $unmount_res
if [[ $unmount_res != *successful* ]]; then
	# 卸载失败
	echo "卸载失败, 挂载点: ${ext_point}, 请检查后重试!!!"
	exit 1
fi
echo "卸载完成, 即将重新挂载!"
echo "---------------------------------------------"

echo "开始检查挂载目录..."
if [ ! -d "/Volumes/${disk_name}" ]; then
	echo "挂载目录: /Volumes/${disk_name} 不存在, 开始创建..."
	echo $PASS_WORD | sudo -S mkdir "/Volumes/${disk_name}"
	# TODO: 判断创建失败case, 比如密码错误等
	echo "挂载目录: /Volumes/${disk_name} 创建成功!"
else
	echo "挂载目录: /Volumes/${disk_name} 已存在!"
fi
echo "---------------------------------------------"

echo "开始以读写模式重新挂载..."
echo $PASS_WORD | sudo -S mount_ntfs "/dev/${ntfs_flag}" "/Volumes/${disk_name}"
# TODO: 判断挂载失败case, 比如密码错误等
echo "挂载完成, 开始验证..."
uuid=`uuidgen`
echo $uuid
valid_file="/Volumes/${disk_name}/${uuid}.txt"
if [ ! -f $valid_file ]; then
	echo "验证文件不存在, 开始创建..."
else
	echo "验证文件已存在, 删除重建..."
	rm -rf $valid_file
fi
touch $valid_file
echo 'success' > $valid_file
valid_result=`cat $valid_file`
if [[ $valid_result == "success" ]]; then
	# 验证成功
	echo "Success! Just enjoy your NTFS disk now!"
	# 删除验证文件
	rm -rf $valid_file
else
	# 验证失败
	echo "Unfortunately! Validate your NTFS disk failed!"
	# 删除验证文件
	rm -rf $valid_file
	exit 1
fi
