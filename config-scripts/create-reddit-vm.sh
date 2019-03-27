gcloud compute instances create reddit-app-immutable\
  --boot-disk-size=10GB \
  --image-family reddit-full \
  --machine-type=g1-small \
  --tags my-net-puma-server \
  --restart-on-failure \
  --network=my-net

