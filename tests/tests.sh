#!/bin/bash

function GetChakraCoreLibDir {
  CPU_TARGET=$1
  OS_TARGET=$2
  local __RESULT=$3
  
  eval $__RESULT=$BASE_DIR/bin/chakracore/$CPU_TARGET-$OS_TARGET
}

function GetChakraCoreLibName {
  CPU_TARGET=$1
  OS_TARGET=$2
  local __RESULT=$3
  
  if [ "$OS_TARGET" = "linux" ]; then
    eval $__RESULT=libChakraCore.so
  elif [ "$OS_TARGET" = "darwin" ]; then
    eval $__RESULT=libChakraCore.dylib
  elif [ "$OS_TARGET" = "win64" -o "$OS_TARGET" = "win32" ]; then
    eval $__RESULT=ChakraCore.dll
  fi
}

function GetLCL {
  CPU_TARGET=$1
  OS_TARGET=$2
  local __RESULT=$3
  
  if [ "$OS_TARGET" = "linux" ]; then
    eval $__RESULT=gtk2
  elif [ "$OS_TARGET" = "darwin" ]; then
    eval $__RESULT=cocoa
  elif [ "$OS_TARGET" = "win64" ]; then
    eval $__RESULT=win32
  elif [ "$OS_TARGET" = "win32" ]; then
    eval $__RESULT=win32
  fi
}

function Clean {
  CPU_TARGET=$1
  OS_TARGET=$2
  
  echo "Cleaning $CPU_TARGET-$OS_TARGET..."

  rm -r $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/*
  rm -r $BASE_DIR/lib/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/*
}

function Build {
  CPU_TARGET=$1
  OS_TARGET=$2

  CHAKRA_CORE_LIB_DIR=
  CHAKRA_CORE_LIB_NAME=
  GetChakraCoreLibDir $CPU_TARGET $OS_TARGET CHAKRA_CORE_LIB_DIR
  GetChakraCoreLibName $CPU_TARGET $OS_TARGET CHAKRA_CORE_LIB_NAME
  CHAKRA_CORE_LIB=$CHAKRA_CORE_LIB_DIR/$CHAKRA_CORE_LIB_NAME

  LCL=
  GetLCL $CPU_TARGET $OS_TARGET LCL 

  FPC_OPTIONS="-n \
    @$FPC_DIR/fpc.cfg \
    -T$OS_TARGET \
    -P$CPU_TARGET \
    -MDelphiUnicode \
    -Scghi \
    -O1 \
    -gl \
    -l \
    -vewnhibq \
    -Fi$BASE_DIR/lib/$CPU_TARGET-$OS_TARGET/$BUILD_MODE \
    -Fl$BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE \
    -Fu$BASE_DIR/src \
    -Fu$BASE_DIR/ext/jedi \
    -Fu$FPCUP_DIR/lazarus/components/fpcunit/lib/$CPU_TARGET-$OS_TARGET/$LCL \
    -Fu$FPCUP_DIR/lazarus/components/fpcunit \
    -Fu$FPCUP_DIR/lazarus/components/synedit/units/$CPU_TARGET-$OS_TARGET/$LCL \
    -Fu$FPCUP_DIR/lazarus/lcl/units/$CPU_TARGET-$OS_TARGET/$LCL \
    -Fu$FPCUP_DIR/lazarus/lcl/units/$CPU_TARGET-$OS_TARGET \
    -Fu$FPCUP_DIR/lazarus/components/lazutils/lib/$CPU_TARGET-$OS_TARGET \
    -Fu$FPCUP_DIR/lazarus/packager/units/$CPU_TARGET-$OS_TARGET \
    -Fu$BASE_DIR/. \
    -FU$BASE_DIR/lib/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/ \
    -FE$BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/ \
    -dLCL \
    -dLCL$LCL"

  if [ "$OS_TARGET" = "linux" ]; then
    FPC_OPTIONS+=" -Cg \
      -k\"-L $CHAKRA_CORE_LIB_DIR\""
  elif [ "$OS_TARGET" = "darwin" ]; then
    FPC_OPTIONS+=" -k\"-force_load $CHAKRA_CORE_LIB\""
  elif [ "$OS_TARGET" = "win64" ]; then
    :;
  elif [ "$OS_TARGET" = "win32" ]; then
    :;
  fi

  mkdir -p $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE
  mkdir -p $BASE_DIR/lib/$CPU_TARGET-$OS_TARGET/$BUILD_MODE

  cp $CHAKRA_CORE_LIB $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE

  echo "Building $CPU_TARGET-$OS_TARGET..."
  FPC_CMD="$FPC_DIR/fpc $FPC_OPTIONS $BASE_DIR/tests/ChakraCoreTests.dpr"
  eval $FPC_CMD
  if [ $? != 0 ]; then
    exit $?
  fi

  FPC_CMD="$FPC_DIR/fpc $FPC_OPTIONS $BASE_DIR/tests/ChakraCoreTestsUI.dpr"
  eval $FPC_CMD
  if [ $? != 0 ]; then
    exit $?
  fi

  ls -lah $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE
}

# On Linux/OSX, libChakraCore.so/libChakraCore.dylib should be installed in a directory
# which is included in the system library path (configured in etc/ld.so.conf),
# e.g. /usr/local/lib or /usr/lib/x86_64-linux-gnu.
# Otherwise set the LD_LIBRARY_PATH environment variable.

function Test {
  CPU_TARGET=$1
  OS_TARGET=$2

  CHAKRA_CORE_LIB_DIR=
  CHAKRA_CORE_LIB_NAME=
  GetChakraCoreLibDir $CPU_TARGET $OS_TARGET CHAKRA_CORE_LIB_DIR
  GetChakraCoreLibName $CPU_TARGET $OS_TARGET CHAKRA_CORE_LIB_NAME
  CHAKRA_CORE_LIB=$CHAKRA_CORE_LIB_DIR/$CHAKRA_CORE_LIB_NAME
  
  TARGET_HOST=
  TARGET_USER=tondrej
  TARGET_DIR=
  
  if [ "$OS_TARGET" = "linux" ]; then
    # arrakis
    TARGET_HOST=arrakis.local
    TARGET_DIR=~/Test   

    echo "Testing $CPU_TARGET-$OS_TARGET on $TARGET_HOST..."
    ssh $TARGET_USER@$TARGET_HOST "mkdir $TARGET_DIR/"
    ssh $TARGET_USER@$TARGET_HOST "rm -r $TARGET_DIR/*"
    scp -r $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/* $TARGET_USER@$TARGET_HOST:$TARGET_DIR/
    ssh $TARGET_USER@$TARGET_HOST "LD_LIBRARY_PATH=$TARGET_DIR/ $TARGET_DIR/ChakraCoreTests --all --progress --format=plain" >> test.log
  elif [ "$OS_TARGET" = "darwin" ]; then
    # kaitain
    TARGET_HOST=kaitain.local
    TARGET_DIR=/Users/tondrej/Test
    DYLD_DIR=/Users/tondrej/Development/ChakraCore/out/Release/bin/ChakraCore

    echo "Testing $CPU_TARGET-$OS_TARGET on $TARGET_HOST..."
    ssh $TARGET_USER@$TARGET_HOST "mkdir $TARGET_DIR/"
    ssh $TARGET_USER@$TARGET_HOST "rm -r $TARGET_DIR/*"
    scp -r $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/* $TARGET_USER@$TARGET_HOST:$TARGET_DIR/
    ssh $TARGET_USER@$TARGET_HOST "DYLD_LIBRARY_PATH=$DYLD_DIR $TARGET_DIR/ChakraCoreTests --all --progress --format=plain" >> test.log
  elif [ "$OS_TARGET" = "win64" ]; then
    # tleilax
    TARGET_HOST=tleilax.local
    TARGET_DIR=C:\\Users\\tondrej\\Test64

    echo "Testing $CPU_TARGET-$OS_TARGET on $TARGET_HOST..."
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "mkdir $TARGET_DIR"
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "del /q /s $TARGET_DIR\\*.*"
    sshpass -p "$PASSWORD" scp -r $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/* $TARGET_USER@$TARGET_HOST:$TARGET_DIR\\
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "$TARGET_DIR\\ChakraCoreTests --all --progress --format=plain" >> test.log
  elif [ "$OS_TARGET" = "win32" ]; then
    # tleilax
    TARGET_HOST=tleilax.local
    TARGET_DIR=C:\\Users\\tondrej\\Test32

    echo "Testing $CPU_TARGET-$OS_TARGET on $TARGET_HOST..."
    echo $PWD
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "mkdir $TARGET_DIR"
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "del /q /s $TARGET_DIR\\*.*"
    sshpass -p "$PASSWORD" scp -r $BASE_DIR/bin/$CPU_TARGET-$OS_TARGET/$BUILD_MODE/* $TARGET_USER@$TARGET_HOST:$TARGET_DIR\\
    sshpass -p "$PASSWORD" ssh $TARGET_USER@$TARGET_HOST "$TARGET_DIR\\ChakraCoreTests --all --progress --format=plain" >> test.log
  fi

}

function Linux {
  Clean x86_64 linux
  Build x86_64 linux
  Test  x86_64 linux
}

function Darwin {
  Clean x86_64 darwin
  Build x86_64 darwin
  Test  x86_64 darwin
}

function Win64 {
  Clean x86_64 win64
  Build x86_64 win64
  Test  x86_64 win64
}

function Win32 {
  Clean i386 win32
  Build i386 win32
  Test  i386 win32
}

BUILD_MODE=Debug
BASE_DIR=`dirname $0`
BASE_DIR=$BASE_DIR/..
FPCUP_DIR=~/fpcupdeluxe
FPC_DIR=$FPCUP_DIR/fpc/bin/x86_64-linux

rm test.log
Linux
Darwin
Win64
Win32
cat test.log

