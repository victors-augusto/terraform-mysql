resource "null_resource" "upload_db" {
    provisioner "file" {
        connection {
            type = "ssh"
            user = "testadmin"
            password = "Password1234!"
            host = data.azurerm_public_ip.IP-Database.ip_address
        }
        source = "mysql"
        destination = "/home/testadmin"
    }

    depends_on = [ time_sleep.wait_30_seconds_db ]
}
resource "null_resource" "deploy_db" {
    triggers = {
        order = null_resource.upload_db.id
    }
    provisioner "remote-exec" {
        connection {
            type = "ssh"
            user = "testadmin"
            password = "Password1234!"
            host = data.azurerm_public_ip.IP-Database.ip_address
        }
        inline = [
            "sudo apt-get update",
            "sudo apt-get install -y mysql-server-5.7",
            "sudo mysql < /home/testadmin/mysql/script/user.sql",
            "sudo cp -f /home/testadmin/mysql/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf",
            "sudo service mysql restart",
            "sleep 20",
        ]
    }
}
  