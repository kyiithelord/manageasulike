# Use official Odoo 18 image as base
FROM odoo:18

# Set maintainer
LABEL maintainer="your-email@example.com"

# Switch to root user to install system dependencies
USER root

# Install additional system packages if needed
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Switch back to odoo user
USER odoo

# Copy custom addons (create this directory structure)
COPY --chown=odoo:odoo ./addons /mnt/extra-addons

# Copy Odoo configuration
COPY --chown=odoo:odoo ./config/odoo.conf /etc/odoo/odoo.conf

# Install Python dependencies if you have a requirements.txt
# COPY --chown=odoo:odoo ./requirements.txt /tmp/requirements.txt
# RUN pip3 install -r /tmp/requirements.txt

# Expose Odoo port
EXPOSE 8069

# Set default command
CMD ["odoo"]
