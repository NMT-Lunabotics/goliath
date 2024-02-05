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
  programs.ros.myIP = "192.168.0.235";
  services.ros.rosbridge.enable = true;

  # Cameras and tracking.
  services.ros.launchServices = {
    d455 = {
      packageName = "realsense2_camera";
      launchFile = "rs_camera.launch";
      rosParams = pkgs.writeText "params.yaml" (builtins.toJSON {
        camera = "d455";
        filters = "pointcloud";
        depth_fps = "30";
        depth_width = "640";
        depth_height = "480";
        enable_color = "false";
        pointcloud_texture_tream = "RS2_STREAM_ANY";
      });
    };
    t265 = {
      packageName = "realsense2_camera";
      launchFile = "rs_t265.launch";
      rosParams = pkgs.writeText "params.yaml" (builtins.toJSON {
        camera = "t265";
      });
    };
  };

  # Pose publishing.
  services.ros.runServices.pose_pub = {
    packageName = "mapping";
    executable = "pose_pub";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };

  # Positioning.
  services.ros.staticTransforms = [
    # Use the t265 for the mapping origin.
    { parent = "map"; child = "t265_odom_frame"; }

    # Robot transforms.
    { parent = "t265_link"; child = "base_link"; }
    {
      parent = "t265_link";
      child = "d455_link";
      x = 0.045;
      z = 0.09;
      pitch = 12.5;
    }
  ];

  # Elevation mapping.
  services.ros.elevationMapping = {
    enable = true;
    pointClouds = [ "d455" ];
    trackPointFrameId = "t265_link";
  };

  # Convert elevation map to occupancy grid.
  services.ros.runServices.cvt_occupancy = {
    packageName = "mapping";
    executable = "cvt_occupancy";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };

  # Autonomous navigation within the occupancy grid.
  services.ros.moveBase = {
    enable = true;
    robotSize = { width = 0.25; length = 0.4; };
    odomFrame = "base_link";
    limits = { forwardMin = 1.0; forward = 3.0; };
  };

  # Conversion from cmd_vel to motor commands.
  services.ros.runServices.motor_ctrl = {
    packageName = "motor_ctrl";
    executable = "motor_ctrl_node";
    workspace = "/home/lunabotics/goliath/catkin_ws";
    rosParams = pkgs.writeText "params.yaml" (builtins.toJSON {
      wheel_diameter = 0.025;
      wheel_base = 0.159;
      max_rpm = 512;
      topics = [ "cmd_vel" "joy_teleop/cmd_vel" "move_base/cmd_vel" ];
    });
  };

  # CAN output to hardware.
  services.ros.runServices.canRawNode = {
    packageName = "can_raw";
    executable = "can_raw_node";
    workspace = "/home/lunabotics/goliath/catkin_ws";
  };
}

