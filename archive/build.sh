WORKSPACE_PATH="../TalyaDemo.xcodeproj"
SCHEME_NAME_APP="TalyaDemo"

SCHEME="Release"

usage() {
  cat << EOF
Usage: $(basename "$0") -s ${SCHEME} -v ${new_version} -b ${new_build_version}
选项：
  -s SCHEME，默认为 Release
  -v 版本号，若不传则使用原版本号；传入 "+"， 则版本号自增
  -b build 号，若不传则使用原 build 号；传入 "+" 则自增
EOF
}

# 获取参数
while getopts "s:v:b:" opt; do
  case $opt in
    p) project_path="$OPTARG";;
    s) SCHEME="$OPTARG";;
    b) new_build_version="$OPTARG";;
    v) new_version="$OPTARG";;
    ?) 
      usage >&2  # 错误时输出帮助
      exit 1
      ;;
    :) echo "选项$OPTARG缺少参数"；exit 1 ;;
  esac
done


SUPPORTED_SCHEMES=("Release")  # 数组形式存储支持的方案

supported=0
for s in "${SUPPORTED_SCHEMES[@]}"; do
  if [[ "$s" == "$SCHEME" ]]; then
    supported=1
    break
  fi
done

if [[ $supported -eq 0 ]]; then
  # 错误处理
  echo "[ERROR] unsupported scheme: ${SCHEME}"
  exit 1
fi

if [ -z "$new_version" ]; then
  new_version=`ruby get_cur_version.rb 0`
  echo "use current version ${new_version}"
elif [ "$new_version" == "+" ]; then
  new_version=`ruby get_new_version.rb 0`
  echo "automatic update version to ${new_version}"
else
  echo "use specific new_version: ${new_version}"
fi

if [ -z "$new_build_version" ]; then
  new_build_version=`ruby get_cur_version.rb 1`
  echo "use current build version ${new_build_version}"
elif [ "$new_build_version" == "+" ]; then
  new_build_version=`ruby get_new_version.rb 1`
  echo "automatic update build version to ${new_build_version}"
else
  echo "use specific new_build_version: ${new_build_version}"
fi

echo "SCHEME: ${SCHEME}"

APP_VERSION="v${new_version}"
OUTPUT_DIR="${APP_VERSION}/${new_build_version}"
BUILD_DIR="${OUTPUT_DIR}/build"

# 创建目录
`rm -rf ${OUTPUT_DIR}`
`mkdir -p ${BUILD_DIR}`

TIMESTAMP=`date +"%Y-%m-%d-%H-%M"`
IPA_PATH="${OUTPUT_DIR}/${SCHEME_NAME_APP}_${APP_VERSION}(${new_build_version})-${TIMESTAMP}-${SCHEME}.ipa"
ARCHIVE_PATH="${OUTPUT_DIR}/${SCHEME_NAME_APP}_${APP_VERSION}(${new_build_version})-${TIMESTAMP}-${SCHEME}.xcarchive"
EXPORT_OPTIONS_PATH="${OUTPUT_DIR}/ExportOptions.plist"

# echo "[build] begin update project version to ${new_version}"
# ruby update_version.rb 0 ${new_version}

# echo "[build] begin update build version to ${new_build_version}"
# ruby update_version.rb 1 ${new_build_version}

# /usr/bin/xcodebuild -workspace ${WORKSPACE_PATH} \
# -scheme ${SCHEME_NAME_APP} \
# -configuration ${SCHEME} clean build \
# -derivedDataPath build \
# ARCHS="arm64" \
# ONLY_ACTIVE_ARCH=NO \

# archive
/usr/bin/xcodebuild archive -project ${WORKSPACE_PATH} \
-scheme ${SCHEME_NAME_APP} -configuration ${SCHEME} -sdk iphoneos clean build \
-archivePath ${BUILD_DIR}/${SCHEME_NAME_APP}.xcarchive

#export
EXPORT_OPTIONS_PList="ExportOptions.plist"

/usr/bin/xcodebuild -exportArchive -archivePath ${BUILD_DIR}/${SCHEME_NAME_APP}.xcarchive \
-exportPath ${OUTPUT_DIR} -exportOptionsPlist ${EXPORT_OPTIONS_PList}

mv ${OUTPUT_DIR}/${SCHEME_NAME_APP}.ipa ${IPA_PATH}
mv ${BUILD_DIR}/${SCHEME_NAME_APP}.xcarchive ${ARCHIVE_PATH}



# 清除 build 目录
rm -rf ${BUILD_DIR}