EXTENSIONS_DIR = $(shell pwd)
UROS_DIR = $(EXTENSIONS_DIR)/micro_ros_src
BUILD_DIR ?= $(EXTENSIONS_DIR)/build

DEBUG ?= 0

ifeq ($(DEBUG), 1)
	BUILD_TYPE = Debug
else
	BUILD_TYPE = Release
endif

# Allow passing includes via file (avoids broken quoting)
ifneq ($(strip $(IDF_INCLUDES_FILE)),)
IDF_INCLUDES := $(shell cat $(IDF_INCLUDES_FILE))
endif

CFLAGS_INTERNAL := $(X_CFLAGS) -ffunction-sections -fdata-sections
CXXFLAGS_INTERNAL := $(X_CXXFLAGS) -ffunction-sections -fdata-sections

# --- macOS/arm64 host colcon settings (fixes libc++/ABI link errors) ---
ifeq ($(shell uname),Darwin)
COLCON_HOST_ARGS := --merge-install \
  --cmake-args -DBUILD_TESTING=OFF -DBUILD_SHARED_LIBS=OFF \
               -DCMAKE_OSX_ARCHITECTURES=arm64 \
               -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
               -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
               -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
               -DCMAKE_SHARED_LINKER_FLAGS="-stdlib=libc++" \
               -DCMAKE_EXE_LINKER_FLAGS="-stdlib=libc++"
else
COLCON_HOST_ARGS := --merge-install --cmake-args -DBUILD_TESTING=OFF
endif
# ----------------------------------------------------------------------

all: $(EXTENSIONS_DIR)/libmicroros.a

clean:
	rm -rf $(EXTENSIONS_DIR)/libmicroros.a; \
	rm -rf $(EXTENSIONS_DIR)/include; \
	rm -rf $(EXTENSIONS_DIR)/esp32_toolchain.cmake; \
	rm -rf $(EXTENSIONS_DIR)/micro_ros_dev; \
	rm -rf $(EXTENSIONS_DIR)/micro_ros_src;

$(EXTENSIONS_DIR)/esp32_toolchain.cmake: $(EXTENSIONS_DIR)/esp32_toolchain.cmake.in
	rm -f $(EXTENSIONS_DIR)/esp32_toolchain.cmake; \
	cat $(EXTENSIONS_DIR)/esp32_toolchain.cmake.in | \
		sed "s/@CMAKE_C_COMPILER@/$(subst /,\/,$(X_CC))/g" | \
		sed "s/@CMAKE_CXX_COMPILER@/$(subst /,\/,$(X_CXX))/g" | \
		sed "s/@CFLAGS@/$(subst /,\/,$(CFLAGS_INTERNAL))/g" | \
		sed "s/@CXXFLAGS@/$(subst /,\/,$(CXXFLAGS_INTERNAL))/g" | \
		sed "s/@IDF_TARGET@/$(subst /,\/,$(IDF_TARGET))/g" | \
		sed "s/@IDF_PATH@/$(subst /,\/,$(IDF_PATH))/g" | \
		sed "s/@BUILD_CONFIG_DIR@/$(subst /,\/,$(BUILD_DIR)/config)/g" \
		> $(EXTENSIONS_DIR)/esp32_toolchain.cmake

$(EXTENSIONS_DIR)/micro_ros_dev/install:
	rm -rf micro_ros_dev; \
	mkdir micro_ros_dev; cd micro_ros_dev; \
	git clone -b humble https://github.com/ament/ament_cmake src/ament_cmake; \
	git clone -b humble https://github.com/ament/ament_lint src/ament_lint; \
	git clone -b humble https://github.com/ament/ament_package src/ament_package; \
	git clone -b humble https://github.com/ament/googletest src/googletest; \
	git clone -b humble https://github.com/ros2/ament_cmake_ros src/ament_cmake_ros; \
	git clone -b humble https://github.com/ament/ament_index src/ament_index; \
	touch src/ament_index/ament_index_cpp/COLCON_IGNORE; \
	CC=clang CXX=clang++ colcon build $(COLCON_HOST_ARGS) --packages-skip ament_index_cpp;

$(EXTENSIONS_DIR)/micro_ros_src/src:
	rm -rf micro_ros_src; \
	mkdir micro_ros_src; cd micro_ros_src; \
	if [ "$(MIDDLEWARE)" = "embeddedrtps" ]; then \
		git clone -b humble https://github.com/micro-ROS/embeddedRTPS src/embeddedRTPS; \
		git clone -b humble https://github.com/micro-ROS/rmw_embeddedrtps src/rmw_embeddedrtps; \
	else \
		git clone -b ros2 https://github.com/eProsima/Micro-XRCE-DDS-Client src/Micro-XRCE-DDS-Client; \
		git clone -b humble https://github.com/micro-ROS/rmw_microxrcedds src/rmw_microxrcedds; \
	fi; \
	git clone -b ros2 https://github.com/eProsima/micro-CDR src/micro-CDR; \
	git clone -b humble https://github.com/micro-ROS/rcl src/rcl; \
	git clone -b humble https://github.com/ros2/rclc src/rclc; \
	git clone -b humble https://github.com/micro-ROS/rcutils src/rcutils; \
	git clone -b humble https://github.com/micro-ROS/micro_ros_msgs src/micro_ros_msgs; \
	git clone -b humble https://github.com/micro-ROS/rosidl_typesupport src/rosidl_typesupport; \
	git clone -b humble https://github.com/micro-ROS/rosidl_typesupport_microxrcedds src/rosidl_typesupport_microxrcedds; \
	git clone -b humble https://github.com/ros2/rosidl src/rosidl; \
	git clone -b humble https://github.com/ros2/rmw src/rmw; \
	git clone -b humble https://github.com/ros2/rcl_interfaces src/rcl_interfaces; \
	git clone -b humble https://github.com/ros2/rosidl_defaults src/rosidl_defaults; \
	git clone -b humble https://github.com/ros2/unique_identifier_msgs src/unique_identifier_msgs; \
	git clone -b humble https://github.com/ros2/common_interfaces src/common_interfaces; \
	git clone -b humble https://github.com/ros2/example_interfaces src/example_interfaces; \
	git clone -b humble https://github.com/ros2/test_interface_files src/test_interface_files; \
	git clone -b humble https://github.com/ros2/rmw_implementation src/rmw_implementation; \
	git clone -b humble https://github.com/ros2/rcl_logging src/rcl_logging; \
	git clone -b humble https://gitlab.com/ros-tracing/ros2_tracing src/ros2_tracing; \
	touch src/ros2_tracing/tracetools_read/COLCON_IGNORE; \
	touch src/ros2_tracing/tracetools_trace/COLCON_IGNORE; \
	touch src/ros2_tracing/tracetools_launch/COLCON_IGNORE; \
	touch src/ros2_tracing/tracetools_test/COLCON_IGNORE; \
	touch src/ros2_tracing/ros2trace/COLCON_IGNORE; \
	git clone -b humble https://github.com/micro-ROS/micro_ros_utilities src/micro_ros_utilities; \
    touch src/rosidl/rosidl_typesupport_introspection_cpp/COLCON_IGNORE; \
    touch src/rcl_logging/rcl_logging_log4cxx/COLCON_IGNORE; \
    touch src/rcl_logging/rcl_logging_spdlog/COLCON_IGNORE; \
    touch src/rclc/rclc_examples/COLCON_IGNORE; \
	touch src/rcl/rcl_yaml_param_parser/COLCON_IGNORE; \
	cp -rf $(EXTRA_ROS_PACKAGES) src/extra_packages || :; \
	test -f src/extra_packages/extra_packages.repos && cd src/extra_packages && vcs import --input extra_packages.repos || :;


$(EXTENSIONS_DIR)/micro_ros_src/install: $(EXTENSIONS_DIR)/esp32_toolchain.cmake $(EXTENSIONS_DIR)/micro_ros_dev/install $(EXTENSIONS_DIR)/micro_ros_src/src
	cd $(UROS_DIR); \
	unset AMENT_PREFIX_PATH; \
	unset ROS_DISTRO; \
	unset ROS_VERSION; \
	export CMAKE_BUILD_PARALLEL_LEVEL=1; \
	export COLCON_DEFAULTS_FILE=/dev/null; \
	PATH="$(subst /opt/ros/$(ROS_DISTRO)/bin,,$(PATH))"; \
	. ../micro_ros_dev/install/local_setup.sh; \
	unset CC; unset CXX; \
	colcon build \
		--executor sequential \
		--parallel-workers 2 \
		--event-handlers console_direct+ \
		--merge-install \
		--packages-ignore-regex=.*_cpp \
		--packages-skip tracetools_read tracetools_trace tracetools_launch tracetools_test ros2trace \
		--metas $(EXTENSIONS_DIR)/colcon.meta $(APP_COLCON_META) \
		--cmake-args \
		"--no-warn-unused-cli" \
		-DCMAKE_TOOLCHAIN_FILE=$(EXTENSIONS_DIR)/esp32_toolchain.cmake \
		-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
		-DCMAKE_VERBOSE_MAKEFILE=ON \
		-DTRACETOOLS_DISABLED=ON \
		-DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=OFF \
		-DTHIRDPARTY=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DIDF_INCLUDES:STRING="$(IDF_INCLUDES)" \
		-DRMW_UXRCE_TRANSPORT=udp \
		-DUCLIENT_PLATFORM=freertos \
		-DUCLIENT_PROFILE_CUSTOM_TRANSPORT=OFF \
		-DUCLIENT_PROFILE_POSIX_TRANSPORT=OFF \
		-DUCLIENT_PROFILE_UDP_TRANSPORT=ON \
		-DUXR_CONFIG_UDP_TRANSPORT_MTU=1200 \
		-DRMW_UXRCE_STREAM_HISTORY_INPUT=8 \
		-DRMW_UXRCE_STREAM_HISTORY_OUTPUT=64 \
		-DRMW_UXRCE_MAX_PUBLISHERS=6

patch_atomic:$(EXTENSIONS_DIR)/micro_ros_src/install
# Workaround https://github.com/micro-ROS/micro_ros_espidf_component/issues/18
ifeq ($(IDF_TARGET),$(filter $(IDF_TARGET),esp32s2 esp32c3 esp32c6))
		echo $(UROS_DIR)/atomic_workaround; \
		mkdir $(UROS_DIR)/atomic_workaround; cd $(UROS_DIR)/atomic_workaround; \
		$(X_AR) x $(UROS_DIR)/install/lib/librcutils.a; \
		$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_fetch_add_8; \
		if [ $(IDF_VERSION_MAJOR) -ge 4 ] && [ $(IDF_VERSION_MINOR) -ge 3 ]; then \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_load_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_store_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_exchange_8; \
		fi; \
		if [ $(IDF_VERSION_MAJOR) -ge 4 ] && [ $(IDF_VERSION_MINOR) -ge 4 ]; then \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_load_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_store_8; \
		fi; \
		if [ $(IDF_VERSION_MAJOR) -ge 5 ] && [ $(IDF_VERSION_MINOR) -ge 0 ]; then \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_load_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_store_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_exchange_8; \
		fi; \
		$(X_AR) rc -s librcutils.a *.obj; \
		cp -rf librcutils.a  $(UROS_DIR)/install/lib/librcutils.a; \
		cd ..; \
		rm -rf $(UROS_DIR)/atomic_workaround;
endif
ifeq ($(IDF_TARGET),$(filter $(IDF_TARGET),esp32 esp32s3))
		echo $(UROS_DIR)/atomic_workaround; \
		mkdir $(UROS_DIR)/atomic_workaround; cd $(UROS_DIR)/atomic_workaround; \
		$(X_AR) x $(UROS_DIR)/install/lib/librcutils.a; \
		$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_fetch_add_8; \
		if [ $(IDF_VERSION_MAJOR) -ge 5 ] && [ $(IDF_VERSION_MINOR) -ge 3 ]; then \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_load_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_store_8; \
			$(X_STRIP) atomic_64bits.c.obj --strip-symbol=__atomic_exchange_8; \
		fi; \
		$(X_AR) rc -s librcutils.a *.obj; \
		cp -rf librcutils.a  $(UROS_DIR)/install/lib/librcutils.a; \
		cd ..; \
		rm -rf $(UROS_DIR)/atomic_workaround;
endif

$(EXTENSIONS_DIR)/libmicroros.a: $(EXTENSIONS_DIR)/micro_ros_src/install patch_atomic
	mkdir -p $(UROS_DIR)/libmicroros; cd $(UROS_DIR)/libmicroros; \
	for file in $$(find $(UROS_DIR)/install/lib/ -name '*.a'); do \
		folder=$$(echo $$file | sed -E "s/(.+)\/(.+).a/\2/"); \
		mkdir -p $$folder; cd $$folder; $(X_AR) x $$file; \
		for f in *; do \
			mv $$f ../$$folder-$$f; \
		done; \
		cd ..; rm -rf $$folder; \
	done ; \
	$(X_AR) rc -s libmicroros.a *.obj; cp libmicroros.a $(EXTENSIONS_DIR); \
	cd ..; rm -rf libmicroros; \
	# libmicroros.mk  (inside the $(EXTENSIONS_DIR)/libmicroros.a rule)
	mkdir -p $(EXTENSIONS_DIR)/include; \
	if [ -d $(UROS_DIR)/install/include ] && [ "$$(ls -A $(UROS_DIR)/install/include 2>/dev/null)" ]; then \
		cp -R $(UROS_DIR)/install/include/* $(EXTENSIONS_DIR)/include/; \
	else \
		echo "WARN: install/include empty; falling back to src headers"; \
		find $(UROS_DIR)/src -maxdepth 3 -type d -name include -exec cp -R {}/\* $(EXTENSIONS_DIR)/include/ \; 2>/dev/null || true; \
	fi
