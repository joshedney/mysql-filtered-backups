FROM ubuntu:18.04

RUN apt update -y && \
    apt install -y \
    curl \
    unzip \
    mysql-client

# Install the AWS CLI - Latest Version
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

WORKDIR /var/lib/mysql-backup

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh wait-for-it.sh

RUN chmod a+x wait-for-it.sh

COPY . /var/lib/mysql-backup/

CMD ["bash", "backup.sh", "backup.conf"]