# Use the official Perl image from the Docker Hub
FROM perl:latest

# Install necessary Perl modules
RUN cpanm --notest HTTP::Server::Simple::CGI
RUN cpanm --notest CGI
RUN cpanm --notest Data::Dumper
RUN cpanm --notest POSIX

# Create a directory for the application
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Copy the Perl script into the container
COPY server.pl /usr/src/app/

# Make the Perl script executable
RUN chmod +x /usr/src/app/server.pl

# Expose the port that the script will run on
EXPOSE 8080

# Run the Perl script
ENTRYPOINT ["perl", "/usr/src/app/server.pl"]
