FROM golang
ADD ./jsonfs /jsonfs
WORKDIR /jsonfs
RUN go get github.com/droyo/jsonfs
RUN go build 
