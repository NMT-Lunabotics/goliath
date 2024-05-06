# This file is for ros4nix.

{ config, pkgs, ... }:
{
  # ---- Base NixOS configuration ----
  imports = [
    ./ros
  ];

  system.stateVersion = "23.05";
  boot.isContainer = true;

  # Change this to the architecture of your system.
  nixpkgs.hostPlatform = "aarch64-linux";

  # ---- Begin ROS configuration ----

  services.ros.enable = true;

  # # Have the ROS master force all the motors to stop when its service
  # # is stopped.
  # systemd.services.rosMaster.serviceConfig.ExecStopPost =
  #   pkgs.writeScript "stop-robot"
  #     ''
  #       #!/bin/sh
  #       cansend can0 001#8000800000000000 || true
  #       cansend can0 003#8080000000000000 || true
  #       cansend can0 007#ffffffffffffffff || true # Turn on all lights
  #     '';

  programs.ros.packages = [
    "xacro"
    "realsense2-camera"
    "robot-state-publisher"
    "teleop-twist-joy"
    "joy"
    "teleop-twist-keyboard"
    "teb-local-planner"
    "navigation"
    "tf2-tools"
    "usb-cam"
    "image-transport"
    "theora-image-transport"
    "compressed-image-transport"
    "apriltag-ros"
  ];

  programs.ros.extraInstallCommands =
    let
      src = pkgs.fetchFromGitHub {
        owner = "stevenlovegrove";
        repo = "Pangolin";
        rev = "v0.9.1";
        sha256 = "sha256-B5YuNcJZHjR3dlVs66rySi68j29O3iMtlQvCjTUZBeY=";
      };

      orb-slam-3 = pkgs.fetchFromGitHub {
        owner = "christoskokas";
        repo = "ORB_SLAM3_noetic";
        rev = "v1.0-release";
        sha256 = "15c0fffae526cec2363bcd66d5aae9970c5ec7a12e77333ca92b54072b8e3288";
      };
    in
    ''
      if [ ! -e /Pangolin ]; then
        cp -r ${src} /Pangolin
        cd /Pangolin

        # Configure and build
        cmake -B build
        cmake --build build

        # Install
        cmake --build build -t install
      fi

      if [ ! -e /ORB_SLAM3_noetic ]; then
        cp -r ${orb-slam-3} /ORB_SLAM3_noetic
        cd /ORB_SLAM3_noetic

        chmod +x build_ros.sh
        ./build_ros.sh
      fi
    '';


  programs.ros.ubuntuPackages = [
    "libeigen3-dev"
  ];

  programs.ros.defaultWorkspace = "/home/lunabotics/goliath/catkin_ws";
  programs.ros.myIP = "192.168.0.207";
  services.ros.rosbridge.enable = true;

  services.ros.elevationMapping.build = true;

  services.ros.realsense2.enable = false;

  # services.ros.runServices.canRawNode = {
  #   packageName = "can_raw";
  #   executable = "can_raw_node";
  #   workspace = "/home/lunabotics/goliath/catkin_ws";
  # };
  # currently included in motor_ctrl/motor.launch

  # Turn on the `motion` LED as soon as Linux boots and gets to this
  # point.
  systemd.services.ros-motion-led = {
    wantedBy = [ "multi-user.target" ];
    after = [ "rosMaster.service" ];
    script = ''
      /var/ros/nixWrappers/rostopic pub /leds/motion std_msgs/Bool true
    '';
  };

  services.ros.runServices = {
    usb-cam = {
      packageName = "usb_cam";
      executable = "usb_cam_node";
      remap._video_device =
        "/dev/v4l/by-id/usb-Arducam_Technology_Co.__Ltd._Arducam_USB_Camera_UC684-video-index0";
    };

    heartbeat_client = {
      workspace = "/home/lunabotics/goliath/catkin_ws";
      packageName = "heartbeat";
      executable = "heartbeat_client_node";
    };

    leds = {
      workspace = "/home/lunabotics/goliath/catkin_ws";
      packageName = "leds";
      executable = "leds_node";
    };
  };

  services.ros.launchServices = {
    motor-ctrl = {
      packageName = "motor_ctrl";
      launchFile = "motor.launch";
      workspace = "/home/lunabotics/goliath/catkin_ws";
    };

    actuator-ctrl = {
      packageName = "actuator_ctrl";
      launchFile = "actuator.launch";
      workspace = "/home/lunabotics/goliath/catkin_ws";
    };

    cameras = {
      packageName = "mapping";
      launchFile = "cameras.launch";
      workspace = "/home/lunabotics/goliath/catkin_ws";
    };

    mapping = {
      packageName = "mapping";
      launchFile = "mapping.launch";
      workspace = "/home/lunabotics/goliath/catkin_ws";
    };
  };

  services.ros.staticTransforms =
    let
      inch = inches: inches * (25.4 / 1000);
    in
    [
      {
        parent = "map";
        child = "t265_odom_frame";
        x = inch (10.53);
        y = inch (-10.273);
        z = inch (14.337);
        # pitch = -90;
      }

      {
        parent = "t265_link";
        child = "base_link_real";
        x = inch (-10.53);
        y = inch (-10.273);
        z = inch (-10.0);
        yaw = 90;
      }

      {
        parent = "base_link_real";
        child = "base_link";
        z = inch (-36);
      }

      {
        parent = "base_link_real";
        child = "d455_left_lr";
        x = inch (10.579);
        y = inch (10.841);
        z = inch (18.034);
        yaw = 30;
      }

      {
        parent = "d455_left_lr";
        child = "d455_left_ud";
        y = inch (0.715);
        z = inch (1.569);
        pitch = 20;
      }

      {
        parent = "d455_left_ud";
        child = "d455_left_link";
        x = inch (0.893);
        y = inch (0.586);
        z = inch (1.550);
      }

      {
        parent = "base_link_real";
        child = "d455_right_lr";
        x = inch (10.579);
        y = inch (-10.841);
        z = inch (18.034);
        yaw = -30;
      }

      {
        parent = "d455_right_lr";
        child = "d455_right_ud";
        y = inch (-0.715);
        z = inch (1.569);
        pitch = 20;
      }

      {
        parent = "d455_right_ud";
        child = "d455_right_link";
        x = inch (0.893);
        y = inch (-0.586);
        z = inch (1.550);
      }

      {
        parent = "base_link_real";
        child = "d435_link";
        # measurements from Niall's phone
        x = inch (-23);
        y = inch (8);
        z = inch (17.5);
        yaw = 180;
      }
    ];
}
