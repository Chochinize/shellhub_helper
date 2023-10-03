viteapp() {
  token="yourtoken"  # create your token on github

  # Check if the user has at least one repository in their account
  user_repos_count=$(curl -s -H "Authorization: Bearer $token" "https://api.github.com/user" | grep -o '"public_repos": [0-9]*' | grep -o '[0-9]*')

  if [ "$user_repos_count" -eq 0 ]; then
    echo "You don't have any repositories in your account. Creating a repository in your account..."

    # Prompt user for repository name
    read -p "Enter a name for the repository: " repo_name

    # Create the repository in the user's account
    response=$(curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $token" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "https://api.github.com/user/repos" \
      -d "{\"name\":\"$repo_name\",\"description\":\"This is your new repository\",\"homepage\":\"https://github.com\",\"private\":true}")

  else
    # Get a list of organizations you're a member of
    orgs=$(curl -s -H "Authorization: Bearer $token" "https://api.github.com/user/orgs" | grep -o '"login": "[^"]*' | awk -F ': "' '{print $2}')

    # Prompt user to select an organization
    echo "Select an organization to create a repository in:"
    select org in $orgs; do
      if [ -n "$org" ]; then
        echo "Creating a repository in the $org organization..."

        # Prompt user for repository name
        read -p "Enter a name for the repository: " repo_name

        # Create the repository using the selected organization and repository name
        response=$(curl -X POST \
          -H "Accept: application/vnd.github+json" \
          -H "Authorization: Bearer $token" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          "https://api.github.com/orgs/$org/repos" \
          -d "{\"name\":\"$repo_name\",\"description\":\"This is your new repository\",\"homepage\":\"https://github.com\",\"private\":true}")

        # Check if the repository creation was successful
        if [[ "$response" == *"\"html_url\":"* ]]; then
          repo_url=$(echo "$response" | grep -o '"html_url": "[^"]*' | awk -F ': "' '{print $2}')
          echo "Repository $repo_name created in the $org organization."
          echo "Repository URL: $repo_url"

          # Prompt user for the name of the Vite-based React app
          read -p "Enter a name for your Vite-based React app: " app_name

          # Create a Vite-based React app with TypeScript
          npx create-vite "$app_name" --template react-ts

          # Navigate into the Vite React app directory
          cd "$app_name"

          # Install Tailwind CSS and its dependencies
          npm install -D tailwindcss postcss autoprefixer

          # Generate tailwind.config.js and postcss.config.js files
          npx tailwindcss init -p

          # Clean the index.css file
          echo > src/index.css

          # Add the content configuration to tailwind.config.js
           sed -i 's|extend: {},|extend: {},\n  content: [\n    "./index.html",\n    "./src/**/*.{js,ts,jsx,tsx}",\n  ],|' tailwind.config.js
          # Add the Tailwind CSS directives to your CSS file
          echo "@tailwind base;" >> src/index.css
          echo "@tailwind components;" >> src/index.css
          echo "@tailwind utilities;" >> src/index.css

          # Initialize a local Git repository and push to the remote GitHub repository
          git init
          git add .
          git commit -m "Initial commit"

          # Set the remote origin to your GitHub repository with the prompted username
          git remote add origin "https://github.com/$org/$repo_name.git"
          git branch -M main
          git push -u origin main
          echo "Local repository pushed to the remote GitHub repository."
        else
          echo "Error creating the repository. Please try again."
        fi
        break
      else
        echo "Invalid selection. Please choose a valid organization."
      fi
    done
  fi
}