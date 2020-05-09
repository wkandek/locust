for i in 20 30 40 50 60 70 80 90 100; 
do 
  echo "NODE_COUNT =" $i > x; 
  grep -v 'NODE_COUNT =' Vagrantfile >> x 
  cp x Vagrantfile
  vagrant up
done
