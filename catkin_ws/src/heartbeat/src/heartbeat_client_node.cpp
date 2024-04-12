#include "ros/ros.h"
#include "std_msgs/Empty.h"
#include "std_msgs/Bool.h"

class HeartbeatClient
{
private:
    ros::NodeHandle nh;
    ros::Subscriber sub;
    ros::Publisher pub;
    ros::Timer timer;
    bool heartbeat_received;

public:
    HeartbeatClient()
    {
        sub = nh.subscribe("/heartbeat", 1000, &HeartbeatClient::heartbeat_callback, this);
        pub = nh.advertise<std_msgs::Bool>("/stop", 1000);
        timer = nh.createTimer(ros::Duration(1.0), &HeartbeatClient::check_heartbeat, this);
        heartbeat_received = false;
    }

    void heartbeat_callback(const std_msgs::Empty::ConstPtr& msg)
    {
        heartbeat_received = true;
    }

    void check_heartbeat(const ros::TimerEvent&)
    {
        if (!heartbeat_received)
        {
            std_msgs::Bool stop_msg;
            stop_msg.data = true;
            pub.publish(stop_msg);
        }
        heartbeat_received = false;
    }
};

int main(int argc, char **argv)
{
    ros::init(argc, argv, "heartbeat_client_node");
    HeartbeatClient hc;

    ros::spin();

    return 0;
}
