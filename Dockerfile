# using nodejs , alpine base image
FROM node:alpine

#create a workdir inside the container
WORKDIR /app

#Copy the package.json and package-lock.json to the working directory
COPY package.json package-lock.json /app/

#install dependencies
RUN npm install

#COPY the entire codebase to the workdir
COPY . /app/

#EXPOSE A PORT FOR the APP
EXPOSE 3000

# start the application
CMD ["npm", "start"]