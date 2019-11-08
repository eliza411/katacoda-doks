curl -sL https://github.com/digitalocean/doctl/releases/download/v1.33.1/doctl-1.33.1-linux-amd64.tar.gz | tar -xzv
sudo mv ~/doctl /usr/local/bin
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "ALL DONE! CONTINUE..."
