keypair=$USER
publickeyfile=$HOME/.ssh/id_rsa.pub
regions=$(ec2-describe-regions -O $AWS_ACCESS_KEY -W $AWS_SECRET_ACCESS | cut -f2)

for region in $regions; do
  echo $region
  ec2-import-keypair -O $AWS_ACCESS_KEY -W $AWS_SECRET_ACCESS --region $region --public-key-file $publickeyfile $keypair
done