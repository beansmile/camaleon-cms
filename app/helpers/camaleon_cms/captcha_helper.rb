=begin
  Camaleon CMS is a content management system
  Copyright (C) 2015 by Owen Peredo Diaz
  Email: owenperedo@gmail.com
  This program is free software: you can redistribute it and/or modify   it under the terms of the GNU Affero General Public License as  published by the Free Software Foundation, either version 3 of the  License, or (at your option) any later version.
  This program is distributed in the hope that it will be useful,  but WITHOUT ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the  GNU Affero General Public License (GPLv3) for more details.
=end
module CamaleonCms::CaptchaHelper

  # build a captcha image
  # len: Number or characters to include in captcha (default 5)
  def cama_captcha_build(len = 5)
    img = MiniMagick::Image.open(File.join($camaleon_engine_dir.present? ? $camaleon_engine_dir : Rails.root.to_s, "lib", "captcha", "captcha_#{rand(12)}.jpg").to_s)
    text = cama_rand_str(len)
    session[:captcha] = text
    img.combine_options do |c|
      # c.resize "150x40"
      c.gravity 'Center'
      c.fill("#FFFFFF")
      c.draw "text 0,5 #{text}"
      c.font File.join($camaleon_engine_dir.present? ? $camaleon_engine_dir : Rails.root.to_s, "lib", "captcha", "bumpyroad.ttf")
      c.pointsize '30'
    end
    img
  end

  # build a captcha tag (image with captcha)
  # img_args: attributes for image_tag
  # input_args: attributes for input field
  def cama_captcha_tag(len = 5, img_args = {alt: ""}, input_args = {})
    input_args[:placeholder] = "Please enter the text of the image" unless input_args[:placeholder].present?
    img_args["onclick"] = "this.src = \"#{cama_captcha_url(len: len)}\"+\"&t=\"+(new Date().getTime());"
    "<div><img style='cursor: pointer;' src='#{cama_captcha_url(len: len)}' #{img_args.collect{|k, v| "#{k}='#{v}'" }.join(" ") } /> <input type='text' name='captcha' #{input_args.collect{|k, v| "#{k}='#{v}'" }.join(" ") } /> </div>"
  end

  # verify captcha value
  def cama_captcha_verified?
    (params[:captcha].present? && params[:captcha].upcase == session[:captcha]) || Rails.env == "test"
  end

  #************************* captcha in attack helpers ***************************#
  # check if the current visitor was submitted 5+ times
  # key: a string to represent a url or form view
  # key must be the same as the form "captcha_tags_if_under_attack(key, ...)"
  def cama_captcha_under_attack?(key)
    session[key] ||= 0
    # if session[key].to_i > 10 then send an email to administrator with request info (ip, browser, if logged then send user info
    session[key].to_i > current_site.get_option("max_try_attack", 5).to_i
  end

  # verify captcha values if this key is under attack
  # key: a string to represent a url or form view
  def captcha_verify_if_under_attack(key)
    cama_captcha_under_attack?(key) ? cama_captcha_verified? : true
  end

  # increment attempts for key by 1
  def cama_captcha_increment_attack(key)
    session[key] ||= 0
    session[key] = session[key].to_i + 1
  end

  # reset the attacks counter for key
  # key: a string to represent a url or form view
  def cama_captcha_reset_attack(key)
    session[key] = 0
  end

  # return a number of attempts for key
  # key: a string to represent a url or form view
  def cama_captcha_total_attacks(key)
    session[key] ||= 0
  end

  # show captcha if under attack
  # key: a string to represent a url or form view
  def cama_captcha_tags_if_under_attack(key, captcha_parmas = [5, {}, {class: "form-control required"}])
    cama_captcha_tag(*captcha_parmas) if cama_captcha_under_attack?(key)
  end

  private
  # generate random string for captcha
  # len: length of characters, default 6
  def cama_rand_str(len=6)
    alphabets = [('A'..'Z').to_a].flatten!
    alphanumerics = [('A'..'Z').to_a,('0'..'9').to_a].flatten!
    str = alphabets[rand(alphabets.size)]
    (len.to_i - 1).times do
      str << alphanumerics[rand(alphanumerics.size)]
    end
    str
  end
end
