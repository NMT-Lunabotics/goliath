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
  ];

  programs.ros.ubuntuPackages = [
    "libeigen3-dev"
  ];
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

  services.ros.launchServices.motor-ctrl = {
    packageName = "motor_ctrl";
    launchFile = "motor.launch";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };

  services.ros.launchServices.actuator-ctrl = {
    packageName = "actuator_ctrl";
    launchFile = "actuator.launch";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };

  services.ros.launchServices.test-map = {
    packageName = "mapping";
    launchFile = "test_map.launch";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };

  services.ros.moveBase = {
    enable = false;
    robotSize = { width = 0.25; length = 0.4; };
    odomFrame = "base_link";
    limits = { forwardMin = 1.0; forward = 3.0; };
  };

  # services.ros.staticTransforms = [
  #   { parent = "sensor_frame"; child = "t265_link"; z = 0.095; }
  #   { parent = "sensor_frame"; child = "d455_link";
  #     x = -0.045; z = 0.185; pitch = 15.0; yaw = 180.0;
  #   }
  #   { parent = "base_link"; child = "sensor_frame";
  #     z = 0.1209;
  #   }

  #   { parent = "t265_odom"; child = "map"; }
  # ];
}

