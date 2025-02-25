# frozen_string_literal: true

# name: discourse-devxy-auth
# about: Allows users to sign in with their Devxy account
# version: 1.0.0
# authors: pat-s
# url: https://github.com/pat-s/discourse-devxy-auth

enabled_site_setting :enable_devxy_login

require 'base64'
require_relative 'lib/validators/DevxyLoginToggle'

register_svg_icon 'devxy-auth-devxy-logo' if respond_to?(:register_svg_icon)

class DevxyAuthenticator < Auth::ManagedAuthenticator
  class DevxyStrategy < OmniAuth::Strategies::OAuth2
    option :name, 'devxy'
    option :scope, 'openid profile email'

    option :client_options,
           site: 'https://git.devxy.io/login/oauth/',
           authorize_url: 'authorize',
           token_url: 'access_token'

    option :authorize_options, %i[scope]

    uid { raw_info['sub'] }

    info do
      {
        name: raw_info['name'],
        email: raw_info['email_verified'] ? raw_info['email'] : nil,
        image: raw_info['picture']
      }
    end

    extra { { 'raw_info' => raw_info } }

    def callback_url
      full_host + script_name + callback_path
    end

    def name
      'devxy'
    end

    def raw_info
      @raw_info ||= JSON.parse(
        Base64.urlsafe_decode64(
          access_token['id_token'].split('.')[1]
        )
      )
    end
  end

  def enabled?
    SiteSetting.enable_devxy_login?
  end

  def name
    'devxy'
  end

  def primary_email_verified?(auth_token)
    auth_token['extra']['raw_info']['email_verified']
  end

  def register_middleware(omniauth)
    omniauth.provider DevxyStrategy,
                      setup: lambda { |env|
                        strategy = env['omniauth.strategy']
                        strategy.options[:client_id] = SiteSetting.devxy_client_id
                        strategy.options[:client_secret] = SiteSetting.devxy_secret
                      }
  end
end

auth_provider authenticator: DevxyAuthenticator.new, icon: 'devxy-auth-devxy-logo'
