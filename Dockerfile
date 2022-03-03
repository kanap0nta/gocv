# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.209.6/containers/go/.devcontainer/base.Dockerfile

# [Choice] Go version (use -bullseye variants on local arm64/Apple Silicon): 1, 1.16, 1.17, 1-bullseye, 1.16-bullseye, 1.17-bullseye, 1-buster, 1.16-buster, 1.17-buster
ARG VARIANT=1-bullseye
FROM golang:${VARIANT}

ARG IS_AMD64
ENV CPU1=${IS_AMD64:+amd64}
ENV CPU1=${CPU1:-arm64}
ENV CPU2=${IS_AMD64:+x86_64}
ENV CPU2=${CPU2:-aarch64}
ENV CPU3=${IS_AMD64:+x86_64}
ENV CPU3=${CPU3:-aarch_64}
ENV CROSS_CPU1=${IS_AMD64:+aarch64}
ENV CROSS_CPU1=${CROSS_CPU1:-x86_64}
ENV CROSS_CPU2=${IS_AMD64:+aarch64}
ENV CROSS_CPU2=${CROSS_CPU2:-x86-64}

# Copy library scripts to execute
COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"
# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Go tools
ENV GO111MODULE=auto
RUN bash /tmp/library-scripts/go-debian.sh "none" "/usr/local/go" "${GOPATH}" "${USERNAME}" "false" \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

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
  && apt-get -y install --no-install-recommends bash-completion v4l-utils gcc-mingw-w64 binutils-mingw-w64 g++-mingw-w64 gcc-${CROSS_CPU2}-linux-gnu g++-${CROSS_CPU2}-linux-gnu make unzip wget build-essential cmake curl git pkg-config \
  && update-alternatives --set i686-w64-mingw32-g++ /usr/bin/i686-w64-mingw32-g++-posix \
  && update-alternatives --set i686-w64-mingw32-gcc /usr/bin/i686-w64-mingw32-gcc-posix \
  && update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix \
  && update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
  && sed -i -e "35,41s:^#::" /etc/bash.bashrc

# Add gocv

ENV GOCV_VERSION=0.29.0
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
RUN printf "set(CMAKE_SYSTEM_NAME Windows)\nset(CMAKE_C_COMPILER   /usr/bin/x86_64-w64-mingw32-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/x86_64-w64-mingw32-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/x86_64-w64-mingw32/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > x86_64_win.cmake \
  && printf "set(CMAKE_SYSTEM_NAME Windows)\nset(CMAKE_C_COMPILER   /usr/bin/i686-w64-mingw32-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/i686-w64-mingw32-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/i686-w64-mingw32/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/i686-w64-mingw32/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > i686_win.cmake \
  && printf "set(CMAKE_SYSTEM_NAME Linux)\nset(CMAKE_C_COMPILER   /usr/bin/aarch64-linux-gnu-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/aarch64-linux-gnu-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/aarch64-linux-gnu/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > aarch64.cmake \
  && printf "set(CMAKE_SYSTEM_NAME Linux)\nset(CMAKE_C_COMPILER   /usr/bin/x86_64-linux-gnu-gcc)\nset(CMAKE_CXX_COMPILER /usr/bin/x86_64-linux-gnu-g++)\nset(ENV{PKG_CONFIG_PATH} /usr/x86_64-linux-gnu/lib/pkgconfig)\nset(CMAKE_FIND_ROOT_PATH /usr/x86_64-linux-gnu/)\nset(CMAKE_CXX_STANDARD 17)\nset(CMAKE_CXX_STANDARD_REQUIRED ON)" > x86_64.cmake \
  && sed -i -e 's/set(OPENCV_PC_LIBS_PRIVATE/list(APPEND OPENCV_PC_LIBS/g' cmake/OpenCVGenPkgconfig.cmake \
  && sed -i -e '130d' 3rdparty/libpng/pngpriv.h \
  && sed -i -e "130i #  if defined(PNG_ARM_NEON) && (defined(__ARM_NEON__) || defined(__ARM_NEON)) && \\\\" 3rdparty/libpng/pngpriv.h
# # Win32 build
# WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_win32
# ENV PKG_CONFIG_PATH=/usr/lib/i686-w64-mingw32/pkgconfig:/usr/i686-w64-mingw32/lib/pkgconfig
# ENV LD_LIBRARY_PATH=/usr/lib/i686-w64-mingw32/:/usr/i686-w64-mingw32/lib
# ENV CGO_CPPFLAGS=-I/usr/i686-w64-mingw32/include/opencv4\ -I/usr/i686-w64-mingw32/include
# ENV CGO_LDFLAGS=-L/usr/i686-w64-mingw32/lib\ -L/usr/i686-w64-mingw32/lib/opencv4/3rdparty\ -lopencv_gapi455\ -lopencv_highgui455\ -lopencv_ml455\ -lopencv_objdetect455\ -lopencv_photo455\ -lopencv_stitching455\ -lopencv_video455\ -lopencv_calib3d455\ -lopencv_features2d455\ -lopencv_dnn455\ -lopencv_flann455\ -lopencv_videoio455\ -lopencv_imgcodecs455\ -lopencv_imgproc455\ -lopencv_core455\ -llibprotobuf\ -lade\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -lwsock32\ -lcomctl32\ -lgdi32\ -lole32\ -lsetupapi\ -lws2_32\ -lcomdlg32\ -loleaut32\ -luuid\ -lvfw32\ -static-libgcc\ -static-libstdc++\ -static
# RUN rm -rf ./* \
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
#   && make -j "$(nproc --all --ignore=1)" \
#   && make preinstall \
#   && make install \
#   && mkdir /usr/i686-w64-mingw32/pkgconfig \
#   && cp unix-install/opencv4.pc /usr/i686-w64-mingw32/pkgconfig/opencv4.pc
# # Win64 build
# WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_win64
# ENV PKG_CONFIG_PATH=/usr/lib/x86_64-w64-mingw32/pkgconfig:/usr/x86_64-w64-mingw32/lib/pkgconfig
# ENV LD_LIBRARY_PATH=/usr/lib/x86_64-w64-mingw32/:/usr/x86_64-w64-mingw32/lib
# ENV CGO_CPPFLAGS=-I/usr/x86_64-w64-mingw32/include/opencv4\ -I/usr/x86_64-w64-mingw32/include
# ENV CGO_LDFLAGS=-L/usr/x86_64-w64-mingw32/lib\ -L/usr/x86_64-w64-mingw32/lib/opencv4/3rdparty\ -lopencv_gapi455\ -lopencv_highgui455\ -lopencv_ml455\ -lopencv_objdetect455\ -lopencv_photo455\ -lopencv_stitching455\ -lopencv_video455\ -lopencv_calib3d455\ -lopencv_features2d455\ -lopencv_dnn455\ -lopencv_flann455\ -lopencv_videoio455\ -lopencv_imgcodecs455\ -lopencv_imgproc455\ -lopencv_core455\ -llibprotobuf\ -lade\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -lwsock32\ -lcomctl32\ -lgdi32\ -lole32\ -lsetupapi\ -lws2_32\ -lcomdlg32\ -loleaut32\ -luuid\ -lvfw32\ -static-libgcc\ -static-libstdc++\ -static
# RUN rm -rf ./* \
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
#   && make -j "$(nproc --all --ignore=1)" \
#   && make preinstall \
#   && make install \
#   && mkdir /usr/x86_64-w64-mingw32/pkgconfig \
#   && cp unix-install/opencv4.pc /usr/x86_64-w64-mingw32/pkgconfig/opencv4.pc
# # Cross build
# WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_${CROSS_CPU1}
# ENV PKG_CONFIG_PATH=/usr/lib/${CROSS_CPU1}-linux-gnu/pkgconfig:/usr/${CROSS_CPU1}-linux-gnu/lib/pkgconfig
# ENV LD_LIBRARY_PATH=/usr/lib/${CROSS_CPU1}-linux-gnu/:/usr/${CROSS_CPU1}-linux-gnu/lib
# ENV CGO_CPPFLAGS=-I/usr/${CROSS_CPU1}-linux-gnu/include/opencv4\ -I/usr/${CROSS_CPU1}-linux-gnu/include
# ENV CGO_LDFLAGS=-L/usr/${CROSS_CPU1}-linux-gnu/lib\ -L/usr/${CROSS_CPU1}-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt
# RUN rm -rf ./* \
#   && cmake -D CMAKE_TOOLCHAIN_FILE=../${CROSS_CPU1}.cmake \
#           -D CMAKE_BUILD_TYPE=RELEASE \
#           -D CMAKE_INSTALL_PREFIX=/usr/${CROSS_CPU1}-linux-gnu \
#           -D BUILD_SHARED_LIBS=OFF \
#           -D BUILD_DOCS=OFF \
#           -D BUILD_EXAMPLES=OFF \
#           -D BUILD_TESTS=OFF \
#           -D BUILD_PERF_TESTS=OFF \
#           -D BUILD_opencv_java=NO \
#           -D BUILD_opencv_python=NO \
#           -D BUILD_opencv_python2=NO \
#           -D BUILD_opencv_python3=NO \
#           -D WITH_TBB=ON \
#           -D WITH_QT=OFF \
#           -D WITH_GTK=OFF \
#           -D WITH_CAROTENE=OFF \
#           -D WITH_CUDA=OFF \
#           -D WITH_CUDNN=OFF \
#           -D WITH_OPENNI=OFF \
#           -D WITH_ITT=OFF \
#           -D WITH_QUIRC=OFF \
#           -D WITH_IPP=OFF \
#           -D OPENCV_FORCE_3RDPARTY_BUILD=ON \
#           -D OPENCV_GENERATE_PKGCONFIG=ON \
#           .. \
#   && make -j "$(nproc --all --ignore=1)" \
#   && make preinstall \
#   && make install
# build
WORKDIR /tmp/opencv/opencv-${OPENCV_VERSION}/build_${CPU2}
ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/${CPU2}-linux-gnu/pkgconfig:/usr/${CPU2}-linux-gnu/lib/pkgconfig
ENV LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:/usr/lib/${CPU2}-linux-gnu/:/usr/${CPU2}-linux-gnu/lib
ENV CGO_CPPFLAGS=-I/usr/${CPU2}-linux-gnu/include/opencv4\ -I/usr/${CPU2}-linux-gnu/include
ENV CGO_LDFLAGS=-L/usr/${CPU2}-linux-gnu/lib\ -L/usr/${CPU2}-linux-gnu/lib/opencv4/3rdparty\ -lopencv_gapi\ -lopencv_highgui\ -lopencv_ml\ -lopencv_objdetect\ -lopencv_photo\ -lopencv_stitching\ -lopencv_video\ -lopencv_calib3d\ -lopencv_features2d\ -lopencv_dnn\ -lopencv_flann\ -lopencv_videoio\ -lopencv_imgcodecs\ -lopencv_imgproc\ -lopencv_core\ -llibprotobuf\ -lade\ -ltbb\ -llibjpeg-turbo\ -llibwebp\ -llibpng\ -llibtiff\ -llibopenjp2\ -lIlmImf\ -lzlib\ -ldl\ -lm\ -lpthread\ -lrt
RUN rm -rf ./* \
  && cmake -D CMAKE_TOOLCHAIN_FILE=../${CPU2}.cmake \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/${CPU2}-linux-gnu \
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
  && make -j "$(nproc --all --ignore=1)" \
  && make preinstall \
  && make install \
  && ldconfig
WORKDIR /tmp/gocv-${GOCV_VERSION}
RUN go clean --cache \
	&& go run -tags customenv ./cmd/version/main.go

WORKDIR /tmp
