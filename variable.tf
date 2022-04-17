variable "region" {
   default = "us-east-1"
}

variable "cidr" {
   default = "10.0.0.0/16"
}

variable "app-sub" {
    default = "10.0.1.0/24"
}

variable "zone1" {
    description = "availability zone1"
    default = "us-east-1a"
}

variable "ami_id" {
   description = "ami id for amazon web server"
    default = "ami-0b0af3577fe5e3532"
}

variable "instance_type" {
    description = "choose instance type"
    default = "t2.medium"
}
