## Example web app for ACIT4640 (Systems and Networks Provisioning)

The app is built on three components:
* the `frontend` (HTML file with inline vanilla JS)
* the `backend` (Python/Flask app)
* the database (MySQL)

There are some changes in the app-setup files.
* backend
  - add backend.conf.j2
  - add backend.service
  - adjust requirements.txt
* frontend
  - adjust default

The parts need to be change when using these configuration files.
* Terraform (main.tf)
  - variable for home cdir block (line 26)
  - variable for path of the public key (line 50)
  - public key name (line 250)
* Ansible 
  - .env (AWS access key / secret key)
  - ansible.cfg (private_key_file)
  - site.yml
    - frontend_file_path (line 8)
    - db username/password/root password(line 71-73)
    - backend file path (line 138)
    - backend requirements file path (line 139)


[Application setup (live demo)]
- Teffaform: https://youtu.be/mXcoci1fhhI 
- Ansible: https://youtu.be/FPyVf0ejl8E?si=3jz-ACNqRSsttM1f