output "public_ip" {
    description = "Public IP address of Spot instance"
    value = "${aws_spot_instance_request.app_server.public_ip}"
}