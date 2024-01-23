terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.105.0"
    }
  }
}

provider "yandex" {
  token     = "keglia_token_yandex"  
  cloud_id  = "b1gto83v8fdqgm5tjb2c" 
  folder_id = "b1g7eg0ncndrirrrbobi" 
  zone = "ru-central1-a"             
}

resource "yandex_compute_instance" "default" {
  name = "new1"
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9b5gvivpqjj7upb4c9l"  
    nat       = true
  }
  metadata = {
    user-data = "${file("./key.yml")}" 
  }
  scheduling_policy {
    preemptible = true  
  }
  connection {
    type        = "ssh"
    user        = "keglia"                            
    private_key = file("/root/.ssh/id_rsa")           
    host        = yandex_compute_instance.default.network_interface.0.nat_ip_address  
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt install openjdk-11-jdk maven git -y",  
      "git clone https://github.com/Stupin87/boxfuse1.git",                
      "cd /home/keglia/boxfuse1 && mvn package"
      "scp /home/keglia/boxfuse1/target/hello-1.0.war keglia@new2_ip:/home/keglia",         
     
         ]
  }
}

resource "yandex_compute_instance" "additional" {
  name = "new2"  
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9b5gvivpqjj7upb4c9l"  
    nat       = true
  }
  metadata = {
    user-data = "${file("./key.yml")}"  
  }
  scheduling_policy {
    preemptible = true  
  }
  connection {
    type        = "ssh"
    user        = "keglia"                             
    private_key = file("/root/.ssh/id_rsa")           
    host        = yandex_compute_instance.additional.network_interface.0.nat_ip_address  
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt install tomcat9 -y",
      "cp /home/keglia/hello-1.0.war /usr/local/tomcat/webapps",      
      
    ]
  }
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

resource "yandex_compute_disk" "ubuntu2004_15GB" {
  type     = "network-ssd"
  zone     = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_image.id
  size     = 15
}
