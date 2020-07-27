dir = $1
port = $2
listen -A 'tcp!*!'$port { export $dir } 
