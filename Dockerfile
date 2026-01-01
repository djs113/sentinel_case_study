FROM python:3.11-slim as builder

WORKDIR /app

RUN pip install mkdocs-material pymdown-extensions

# Copy the project files
COPY . .

RUN mkdocs build

FROM nginx:alpine

# Copy the built HTML from the builder stage to Nginx
COPY --from=builder /app/site /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]