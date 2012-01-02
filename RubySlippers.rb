#!/usr/bin/env ruby
# RubySlippers - There is no place like /home

require "fileutils"
require "rubygems"
require "thor"
require "grit"

include Grit
class RubySlippers < Thor
  include Thor::Actions

  @@source_root = File.expand_path("../", __FILE__)
  @@repository = @@source_root + "/home"
  @@home = ENV["HOME"]

  desc "commit", "Commit any modified files in your repository"
  method_option :debug, :type => :boolean
  def commit()
    self.commit(options)
  end

  desc "push", "Forced push"
  method_option :debug, :type => :boolean
  def push()
    self.push(options)
  end

  desc "pull", "Forced pull"
  method_option :debug, :type => :boolean
  def pull()
    self.pull(options)
  end

  desc "init GIT_URI", "Initialize and setup your home repository"
  method_option :debug, :type => :boolean
  def init(uri)
    if File.exists?(@@repository + "/.git")
      say "Repository already exists!", :red
      exit 1
    else
      FileUtils.mkdir @@repository if ! File.exists?(@@repository) 
      Grit.debug = true if options[:debug]
      grit = Grit::Git.new(@@repository)
      grit.clone({}, uri, @@repository)
    end
  end

  desc "carry FILE [TARGET]", "Carry a file or directory in your repository"
  method_option :debug, :type => :boolean
  method_option :force, :type => :boolean, :alias => "-f"
  def carry(file, target=nil)
    if ! File.exists?(file)
      say "File not found!", :red
      exit 1
    elsif ! file.match(/^\//)
      file = Dir.pwd + "/" + file
    end

    if ! target.nil?
      target = @@repository + "/" + target
      if File.directory?(target)
        target.slice(-1,1) if target.match(/\/$/)
        target << "/" + File.basename(file)
      end
    else
      target = @@repository + "/" + File.basename(file)
    end

    if File.exists?(target)
      if ! options[:force]
        say "Target file already exists!", :red
        exit 1
      end
    elsif ! File.exists?(File.dirname(target))
      FileUtils.mkdir_p(File.dirname(target))
    end

    if File.directory?(file)
      FileUtils.cp_r(file, target)
    else
      FileUtils.cp(file, target)
    end

    Dir.chdir(@@repository) do
      target.gsub!(@@repository + "/", "")

      Grit.debug = true if options[:debug]
      repo = Grit::Repo.new(@@repository)
      repo.add(target)
      repo.commit_index("CARRY #{target}")

      self.push
      say "You are carrying #{target}"
    end
  end

  desc "drop FILE", "Drop (delete) a file or directory from your repository"
  method_option :debug, :type => :boolean
  def drop(file)
    if ! file.match(/^\//)
      file = @@repository + "/" + file
    elsif ! file.match(/^#{@@repository}/)
      say "Cannot drop file outsie of repository!", :red
      exit 1
    end

    if ! File.exists?(file)
      say "File does not exist!", :red
      exit 1
    elsif File.directory?(file)
      FileUtils.remove(file, :recursive)
    else
      FileUtils.remove(file)
    end

    Dir.chdir(@@repository) do
      file.gsub!(@@repository + "/", "")

      Grit.debug = true if options[:debug]
      repo = Grit::Repo.new(@@repository)
      repo.remove(file)
      repo.commit_index("DROP #{file}")

      self.push
      say "You have dropped #{file}"
    end
  end

  desc "equip FILE TARGET", "Symlink file from repository into your home directory"
  method_option :debug, :type => :boolean
  method_option :force, :type => :boolean
  method_option :persist, :type => :boolean, :alias => "-p"
  def equip(file, target)
    if file.match(/^\//) && ! file.match(/^#{@@repository}/)
      say "Equiped file path should be relative to repository root", :red
      exit 1
    else
      file = @@repository + "/" + file
    end

    if ! File.exists?(file)
      say "File does not exist!", :red
      exit 1
    end

    if target.nil?
      target = @@home + "/" + File.basename(file)
    elsif target.match(/^\//) && ! file.match(/^#{@@home}/)
      say "Target file must be in your home dir", :red
      exit 1
    else
      target = @@home + "/" + target
    end

    if File.exists?(target)
      if ! File.symlink?(target)
        if ! options[:force]
          say "Target file exists!", :red
          exit 1
        else
          FileUtils.mv(target, target + ".rsbkup")
        end
      elsif File.readlink(target) != file
        FileUtils.mv(target, target + ".rsbkup")
      else
        say "File is already equipped!"
        exit 0
      end
    end

    FileUtils.ln_s(file, target)

    if options[:persist]
      # persistance
    end
  end

  desc "unequip FILE", "Unequip a file from your repository"
  method_option :debug, :type => :boolean
  method_option :force, :type => :boolean
  method_option :persist, :type => :boolean
  method_option :restore, :type => :boolean
  def unequip(file)
    if file.match(/^\//) && ! file.match(/^#{@@home}/)
      say "Equipped file path should be relative to your home dir", :red
      exit 1
    else
      file = @@home + "/" + file
    end

    if ! File.exists?(file)
      say "File does not exist!", :red
      exit 1
    else
      if ! File.symlnk?(file)
        say "File is not a symlink!", :red
        exit 1
      elsif ! File.readlink(file).match(/^#{@@repository}/)
        say "File does not appear to be a previously equipped file!", :reda
        exit 1 
      end
    end

    if File.exists?(file + ".rsbkup") && options[:restore]
      FileUtils.mv(file + ".rsbkup", file)
    else
      FileUtils.rm(file)
    end

    if options[:persist]
      # persistance
    end
  end

  no_tasks do
    def pull(options={})
      Grit.debug = true if options[:debug]
      grit = Grit::Git.new(@@repository + "/.git")
      grit.pull({}, "origin", "master")
    end

    def push(options={})
      Grit.debug = true if options[:debug]
      grit = Grit::Git.new(@@repository + "/.git") 
      grit.push({}, "origin", "master")
    end

    def commit(options={})
      Grit.debug = true if options[:debug]
      repo = Grit::Repo.new(@@repository)

      if repo.status.changed.any?      
        say "You have uncommited changes in your repository!", :red
        repo.status.changed.each do |k,f|
          say "M\t#{f.path}"
        end

        confirm = ask "Do you want to commit these changes now? [y,n]: "
        
        if confirm == "y"
          Dir.chdir(@@repository) do 
            repo.status.changed.each do |k,f|
              file = f.path.gsub(/^#{@@repository}/, "")
              repo.add(file)
            end
          end
        end

        repo.commit_index("COMMIT MODIFIED FILES")
        self.push
      end
    end
  end
end

RubySlippers.start
