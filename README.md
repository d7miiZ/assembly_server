# x86_64 Assembly HTTP Server

This is a minimal HTTP server written entirely in x86_64 assembly for Linux. It handles basic GET and POST requests by directly using Linux syscalls.

## Build
```bash
 gcc -nostdlib -o server server.s 
```

## Features

The server forks a new child process to handle each incoming connection.

* **GET Requests:** The server parses the path from the GET request (e.g., `/index.html`). It then attempts to open that file from its local directory, read its contents, and send them back to the client with a `HTTP/1.0 200 OK` header.

* **POST Requests:** The server parses the path from the POST request (e.g., `/upload.txt`). It then creates or overwrites this file locally, writing the entire body (payload) of the POST request into it. It responds with a `HTTP/1.0 200 OK` header.

## How to Run

The server is hard-coded to bind to port 80. This requires root privileges to run.

```bash
sudo ./server
```

## How to Test

You can use curl in a separate terminal to test the server.

### Test GET

Create a file for the server to find:

```bash
echo "Hello from assembly server!" > /index.html
```

Run the server (in another terminal):

```bash
sudo ./server
```

Request the file using curl:

```bash
curl http://localhost/index.html
```

You should see the output: Hello from assembly server!

### Test POST

```bash
curl -X POST http://localhost/uploaded.txt -d "This is data from a POST request."
```

Check the server's directory for the newly created file:

```bash
cat /uploaded.txt
```

You should see the output: This is data from a POST request.
