namespace :deploy do
  desc "Create a symlink to docker hub creds"
  task :create_creds_symlink do
    on roles(:app) do
      execute "ln -s #{shared_path}/config/environment_variables.yml #{release_path}/config/environment_variables.yml "
    end
  end
end

after 'deploy:symlink:linked_dirs', 'deploy:create_creds_symlink'