class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :store_location, :set_user_id, :set_locale
  # before_action :ensure_signup_complete, only: [:new, :create, :update, :destroy]

  # before_action do
  #   if current_user && current_user.admin?
  #     Rack::MiniProfiler.authorize_request
  #   end
  # end

  def after_sign_in_path_for(resource)
    cookies.signed[:user_id] = current_user.id
    session[:previous_url] || root_path
  end

  def current_or_guest_user
    if current_user
      if session[:guest_user_id] && session[:guest_user_id] != current_user.id
        logging_in
        # reload guest_user to prevent caching problems before destruction
        guest_user(with_retry = false).try(:reload).try(:destroy)
        session[:guest_user_id] = nil
      end
      current_user
    else
      guest_user
    end
  end
  helper_method :current_or_guest_user

  # find guest_user object associated with the current session,
  # creating one as needed
  def guest_user(with_retry = true)
    # Cache the value the first time it's gotten.
    @cached_guest_user ||= User.find(session[:guest_user_id] ||= create_guest_user.id)

  rescue ActiveRecord::RecordNotFound # if session[:guest_user_id] invalid
     session[:guest_user_id] = nil
     guest_user if with_retry
  end

  private

  def set_locale
    I18n.locale = params[:locale] ||
      extract_locale_from_accept_language_header ||
      I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    http_accept_language.compatible_language_from I18n.available_locales
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    return unless request.get?
    dont_store_paths = %w(
      /users/sign_in
      /users/sign_up
      /users/password/new
      /users/password/edit
      /users/confirmation
      /users/sign_out
    )
    if !dont_store_paths.include?(request.path) &&
      not_omniauth_paths(request.path) && !request.xhr?
      session[:previous_url] = request.fullpath
    end
  end

  def not_omniauth_paths path_name
    /^\/users\/auth\// !~ path_name
  end

  # Will be removed some day
  def set_user_id
    if request.get? && current_user && cookies.signed[:user_id].blank?
      cookies.signed[:user_id] = current_user.id
    end
  end

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  # called (once) when the user logs in, insert any code your application needs
  # to hand off from guest_user to current_user.
  def logging_in
    # For example:
    # guest_comments = guest_user.comments.all
    # guest_comments.each do |comment|
      # comment.user_id = current_user.id
      # comment.save!
    # end
  end

  def create_guest_user
    u = User.create(:name => "guest", :email => "guest_#{Time.now.to_i}#{rand(100)}@example.com")
    u.save!(:validate => false)
    session[:guest_user_id] = u.id
    u
  end

end
