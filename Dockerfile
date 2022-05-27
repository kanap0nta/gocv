# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.234.0/containers/go/.devcontainer/base.Dockerfile

# [Choice] Go version (use -bullseye variants on local arm64/Apple Silicon): 1, 1.16, 1.17, 1-bullseye, 1.16-bullseye, 1.17-bullseye, 1-buster, 1.16-buster, 1.17-buster
ARG VARIANT="1.18-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/go:0-${VARIANT}

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment the next lines to use go get to install anything else you need
# USER vscode
# RUN go get -x <your-dependency-or-tool>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

WORKDIR /tmp

# Add tools

RUN apt-get update \
  && ARCH=$(arch) \
  && if [ "$ARCH" = "aarch64" ]; then CROSS_GCC_PACKAGE=gcc-x86-64-linux-gnu\ g++-x86-64-linux-gnu; else CROSS_GCC_PACKAGE=gcc-aarch64-linux-gnu\ g++-aarch64-linux-gnu; fi \
  && apt-get -y install --no-install-recommends v4l-utils make unzip wget build-essential cmake curl git pkg-config gcc-mingw-w64 binutils-mingw-w64 g++-mingw-w64 ${CROSS_GCC_PACKAGE} \
  && update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix \
  && update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix \
  && update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix \
  && update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
  && apt-get clean \
  && rm -r /var/lib/apt/lists/*

# Add gocv

ENV GOCV_VERSION=0.30.0
ENV GOCV_URL=https://github.com/hybridgroup/gocv/archive/refs/tags/v${GOCV_VERSION}.zip
ENV OPENCV_VERSION=4.5.5
ENV OPENCV_URL=https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
# export CGO_CPPFLAGS=`pkg-config --cflags opencv4`
# export CGO_LDFLAGS=`pkg-config --libs opencv4`
RUN curl -L -o gocv.zip $GOCV_URL \
  && unzip gocv.zip
WORKDIR /tmp/opencv
RUN curl -Lo opencv.zip $OPENCV_URL \
	&& unzip -q opencv.zip
WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}
RUN printf "set(CMAKE_SYSTEM_NAME Linux)\nset(CMAKE_C_COMPILER   /usr/bin/aarch64-linux-gnu-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/aarch64-linux-gnu/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > aarch64.cmake \
  && printf "set(CMAKE_SYSTEM_NAME Linux)\nset(CMAKE_C_COMPILER   /usr/bin/x86_64-linux-gnu-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/x86_64-linux-gnu-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/x86_64-linux-gnu/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/x86_64-linux-gnu/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > x86_64.cmake \
  # && printf "set(CMAKE_SYSTEM_NAME Windows)\nset(CMAKE_C_COMPILER   /usr/bin/x86_64-w64-mingw32-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/x86_64-w64-mingw32-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/x86_64-w64-mingw32/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > x86_64_win.cmake \
  # && printf "set(CMAKE_SYSTEM_NAME Windows)\nset(CMAKE_C_COMPILER   /usr/bin/i686-w64-mingw32-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/i686-w64-mingw32-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/i686-w64-mingw32/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > i686_win.cmake \
  && sed -i -e 's/set(OPENCV_PC_LIBS_PRIVATE/list(APPEND OPENCV_PC_LIBS/g' cmake/OpenCVGenPkgconfig.cmake \
  && sed -i -e '130d' 3rdparty/libpng/pngpriv.h \
  && sed -i -e "130i #  if defined(PNG_ARM_NEON) && (defined(__ARM_NEON__) || defined(__ARM_NEON)) && \\\\" 3rdparty/libpng/pngpriv.h
# # Win32 build
# WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_win32
# RUN rm -rf ./* \
#   && PKG_CONFIG_PATH=/usr/lib/i686-w64-mingw32/pkgconfig:/usr/i686-w64-mingw32/lib/pkgconfig \
#   && LD_LIBRARY_PATH=/usr/lib/i686-w64-mingw32/:/usr/i686-w64-mingw32/lib \
#   && CGO_CPPFLAGS=-I/usr/i686-w64-mingw32/include/opencv4\ -I/usr/i686-w64-mingw32/include \
#   && CGO_LDFLAGS=-L/usr/i686-w64-mingw32/lib\ -L/usr/i686-w64-mingw32/lib/opencv4/3rdparty\ -lopencv_gapi455\ -lopencv_highgui455\ -lopencv_ml455\ -lopencv_objdetect455\ -lopencv_photo455\ -lopencv_stitching455\ -lopencv_video455\ -lopencv_calib3d455\ -lopencv_features2d455\ -lopencv_dnn455\ -lopencv_flann455\ -lopencv_videoio455\ -lopencv_imgcodecs455\ -lopencv_imgproc455\ -lopencv_core455\ -llibprotobuf\ -lade\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -lwsock32\ -lcomctl32\ -lgdi32\ -lole32\ -lsetupapi\ -lws2_32\ -lcomdlg32\ -loleaut32\ -luuid\ -lvfw32\ -static-libgcc\ -static-libstdc++\ -static \
#   && cmake -D CMAKE_TOOLCHAIN_FILE=../i686_win.cmake \
#           -D CMAKE_BUILD_TYPE=RELEASE \
#           -D CMAKE_INSTALL_PREFIX=/usr/i686-w64-mingw32 \
#           -D BUILD_SHARED_LIBS=OFF \
#           -D BUILD_DOCS=OFF \
#           -D BUILD_EXAMPLES=OFF \
#           -D BUILD_TESTS=OFF \
#           -D BUILD_PERF_TESTS=OFF \
#           -D BUILD_opencv_java=NO \
#           -D BUILD_opencv_python=NO \
#           -D BUILD_opencv_python2=NO \
#           -D BUILD_opencv_python3=NO \
#           -D WITH_TBB=OFF \
#           -D WITH_QT=OFF \
#           -D WITH_GTK=OFF \
#           -D WITH_CAROTENE=OFF \
#           -D WITH_CUDA=OFF \
#           -D WITH_CUDNN=OFF \
#           -D WITH_OPENNI=OFF \
#           -D WITH_ITT=OFF \
#           -D WITH_QUIRC=OFF \
#           -D OPENCV_FORCE_3RDPARTY_BUILD=ON \
#           -D OPENCV_GENERATE_PKGCONFIG=ON \
#           .. \
#   && make -j "$(nproc --all)" \
#   && make preinstall \
#   && make install \
#   && mkdir /usr/i686-w64-mingw32/pkgconfig \
#   && cp unix-install/opencv4.pc /usr/i686-w64-mingw32/pkgconfig/opencv4.pc
# # Win64 build
# WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_win64
# RUN rm -rf ./* \
#   && PKG_CONFIG_PATH=/usr/lib/x86_64-w64-mingw32/pkgconfig:/usr/x86_64-w64-mingw32/lib/pkgconfig \
#   && LD_LIBRARY_PATH=/usr/lib/x86_64-w64-mingw32/:/usr/x86_64-w64-mingw32/lib \
#   && CGO_CPPFLAGS=-I/usr/x86_64-w64-mingw32/include/opencv4\ -I/usr/x86_64-w64-mingw32/include \
#   && CGO_LDFLAGS=-L/usr/x86_64-w64-mingw32/lib\ -L/usr/x86_64-w64-mingw32/lib/opencv4/3rdparty\ -lopencv_gapi455\ -lopencv_highgui455\ -lopencv_ml455\ -lopencv_objdetect455\ -lopencv_photo455\ -lopencv_stitching455\ -lopencv_video455\ -lopencv_calib3d455\ -lopencv_features2d455\ -lopencv_dnn455\ -lopencv_flann455\ -lopencv_videoio455\ -lopencv_imgcodecs455\ -lopencv_imgproc455\ -lopencv_core455\ -llibprotobuf\ -lade\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -lwsock32\ -lcomctl32\ -lgdi32\ -lole32\ -lsetupapi\ -lws2_32\ -lcomdlg32\ -loleaut32\ -luuid\ -lvfw32\ -static-libgcc\ -static-libstdc++\ -static \
#   && cmake -D CMAKE_TOOLCHAIN_FILE=../x86_64_win.cmake \
#           -D CMAKE_BUILD_TYPE=RELEASE \
#           -D CMAKE_INSTALL_PREFIX=/usr/x86_64-w64-mingw32 \
#           -D BUILD_SHARED_LIBS=OFF \
#           -D BUILD_DOCS=OFF \
#           -D BUILD_EXAMPLES=OFF \
#           -D BUILD_TESTS=OFF \
#           -D BUILD_PERF_TESTS=OFF \
#           -D BUILD_opencv_java=NO \
#           -D BUILD_opencv_python=NO \
#           -D BUILD_opencv_python2=NO \
#           -D BUILD_opencv_python3=NO \
#           -D WITH_TBB=OFF \
#           -D WITH_QT=OFF \
#           -D WITH_GTK=OFF \
#           -D WITH_CAROTENE=OFF \
#           -D WITH_CUDA=OFF \
#           -D WITH_CUDNN=OFF \
#           -D WITH_OPENNI=OFF \
#           -D WITH_ITT=OFF \
#           -D WITH_QUIRC=OFF \
#           -D OPENCV_FORCE_3RDPARTY_BUILD=ON \
#           -D OPENCV_GENERATE_PKGCONFIG=ON \
#           .. \
#   && make -j "$(nproc --all)" \
#   && make preinstall \
#   && make install \
#   && mkdir /usr/x86_64-w64-mingw32/pkgconfig \
#   && cp unix-install/opencv4.pc /usr/x86_64-w64-mingw32/pkgconfig/opencv4.pc
# Cross build
WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_cross
RUN rm -rf ./* \
  && ARCH=$(arch) \
  && if [ "$ARCH" = "aarch64" ]; then CROSS_ARCH=x86_64; else CROSS_ARCH=aarch64; fi \
  && PKG_CONFIG_PATH=/usr/lib/${CROSS_ARCH}-linux-gnu/pkgconfig:/usr/${CROSS_ARCH}-linux-gnu/lib/pkgconfig \
  && LD_LIBRARY_PATH=/usr/lib/${CROSS_ARCH}-linux-gnu/:/usr/${CROSS_ARCH}-linux-gnu/lib \
  && CGO_CPPFLAGS=-I/usr/${CROSS_ARCH}-linux-gnu/include/opencv4\ -I/usr/${CROSS_ARCH}-linux-gnu/include \
  && CGO_LDFLAGS=-L/usr/${CROSS_ARCH}-linux-gnu/lib\ -L/usr/${CROSS_ARCH}-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt \
  && cmake -D CMAKE_TOOLCHAIN_FILE=../${CROSS_ARCH}.cmake \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/${CROSS_ARCH}-linux-gnu \
          -D BUILD_SHARED_LIBS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_opencv_java=NO \
          -D BUILD_opencv_python=NO \
          -D BUILD_opencv_python2=NO \
          -D BUILD_opencv_python3=NO \
          -D WITH_TBB=ON \
          -D WITH_QT=OFF \
          -D WITH_GTK=OFF \
          -D WITH_CAROTENE=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_CUDNN=OFF \
          -D WITH_OPENNI=OFF \
          -D WITH_ITT=OFF \
          -D WITH_QUIRC=OFF \
          -D WITH_IPP=OFF \
          -D OPENCV_FORCE_3RDPARTY_BUILD=ON \
          -D OPENCV_GENERATE_PKGCONFIG=ON \
          .. \
  && make -j "$(nproc --all)" \
  && make preinstall \
  && make install
# build
WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build
RUN rm -rf ./* \
  && ARCH=$(arch) \
  && PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/${ARCH}-linux-gnu/pkgconfig:/usr/${ARCH}-linux-gnu/lib/pkgconfig \
  && LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:/usr/lib/${ARCH}-linux-gnu/:/usr/${ARCH}-linux-gnu/lib \
  && CGO_CPPFLAGS=-I/usr/${ARCH}-linux-gnu/include/opencv4\ -I/usr/${ARCH}-linux-gnu/include \
  && CGO_LDFLAGS=-L/usr/${ARCH}-linux-gnu/lib\ -L/usr/${ARCH}-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt \
  && cmake -D CMAKE_TOOLCHAIN_FILE=../${ARCH}.cmake \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/${ARCH}-linux-gnu \
          -D BUILD_SHARED_LIBS=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_EXAMPLES=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D BUILD_opencv_java=NO \
          -D BUILD_opencv_python=NO \
          -D BUILD_opencv_python2=NO \
          -D BUILD_opencv_python3=NO \
          -D WITH_TBB=ON \
          -D WITH_QT=OFF \
          -D WITH_GTK=OFF \
          -D WITH_CAROTENE=OFF \
          -D WITH_CUDA=OFF \
          -D WITH_CUDNN=OFF \
          -D WITH_OPENNI=OFF \
          -D WITH_ITT=OFF \
          -D WITH_QUIRC=OFF \
          -D WITH_IPP=OFF \
          -D OPENCV_FORCE_3RDPARTY_BUILD=ON \
          -D OPENCV_GENERATE_PKGCONFIG=ON \
          .. \
  && make -j "$(nproc --all)" \
  && make preinstall \
  && make install \
  && ldconfig

RUN printf "export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/$(arch)-linux-gnu/pkgconfig:/usr/$(arch)-linux-gnu/lib/pkgconfig\n" >> ~/.zshrc
RUN printf "export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:/usr/lib/$(arch)-linux-gnu/:/usr/$(arch)-linux-gnu/lib\n" >> ~/.zshrc
RUN printf "export CGO_CPPFLAGS=-I/usr/$(arch)-linux-gnu/include/opencv4\ -I/usr/$(arch)-linux-gnu/include\n" >> ~/.zshrc
RUN printf "export CGO_LDFLAGS=-L/usr/$(arch)-linux-gnu/lib\ -L/usr/$(arch)-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt\n" >> ~/.zshrc
RUN printf "export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/$(arch)-linux-gnu/pkgconfig:/usr/$(arch)-linux-gnu/lib/pkgconfig\n" >> ~/.bashrc
RUN printf "export LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:/usr/lib/$(arch)-linux-gnu/:/usr/$(arch)-linux-gnu/lib\n" >> ~/.bashrc
RUN printf "export CGO_CPPFLAGS=-I/usr/$(arch)-linux-gnu/include/opencv4\ -I/usr/$(arch)-linux-gnu/include\n" >> ~/.bashrc
RUN printf "export CGO_LDFLAGS=-L/usr/$(arch)-linux-gnu/lib\ -L/usr/$(arch)-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt\n" >> ~/.bashrc
WORKDIR /tmp/gocv-${GOCV_VERSION}
SHELL ["/bin/zsh", "-c"]
RUN source ~/.zshrc \
  && go clean --cache \
  && go run -tags customenv ./cmd/version/main.go

WORKDIR /tmp
RUN rm -rf opencv
