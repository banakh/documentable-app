FROM node:lts-alpine

WORKDIR /app

# ENV PATH /app/node_modules/.bin:$PATH

COPY package.json /app/package.json

RUN npm install

COPY . .
RUN npm install @vue/cli -g

CMD ["npm", "run", "serve"]
