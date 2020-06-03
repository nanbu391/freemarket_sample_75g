class CardsController < ApplicationController
  require 'payjp'
  
  def index
    if @card.present?
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      customer = Payjp::Customer.retrieve(@card.payjp_id)
      @card_info = customer.cards.retrieve(customer.default_card)
      @card_brand = @card_info.brand
      @exp_month = @card_info.exp_month.to_s
      @exp_year = @card_info.exp_year.to_s.slice(2,3) 
      case @card_brand
      when "Visa"
        @card_image = "VISA.png"
      when "JCB"
        @card_image = "JCB.jpg"
      when "MasterCard"
        @card_image = "MasterCard.png"
      when "American Express"
        @card_image = "AMERICAN EXPRESS.pngg"
      when "Diners Club"
        @card_image = "DinersClub.jpg"
      when "Discover"
        @card_image = "DISCOVER.jpg"
      end
    end
  end

  def new
    redirect_to action: "index" if @card.present?    
  end

  def create
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
    if params['payjpToken'].blank?
      render "new"
    else
      customer = Payjp::Customer.create(
        description: 'test',
        email: current_user.email,
        card: params['payjpToken'],
        metadata: {user_id: current_user.id}
      )
      @card = Creditcard.new(user_id: current_user.id, payjp_id: customer.id)
      if @card.save
        redirect_to action: "index", notice:"支払い情報の登録が完了しました"
      else
        render 'new'
      end
    end
  end

  def destroy     
    Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
    customer = Payjp::Customer.retrieve(@card.payjp_id)
    customer.delete 
    if @card.destroy 
      redirect_to action: "index", notice: "削除しました"
    else
      redirect_to action: "index", alert: "削除できませんでした"
    end
  end

  def buy
    @product = Product.find(params[:product_id])
    if @product.buyer.present? 
      redirect_back(fallback_location: root_path) 
    elsif @card.blank?
      redirect_to action: "new"
      flash[:alert] = '購入にはクレジットカード登録が必要です'
    else
      Payjp.api_key = ENV["PAYJP_PRIVATE_KEY"]
      Payjp::Charge.create(
      amount: @product.price,
      customer: @card.customer_id,
      currency: 'jpy',
      )
      if @product.update(buyer_id: current_user.id)
        flash[:notice] = '購入しました。'
        redirect_to controller: 'products', action: 'show', id: @product.id
      else
        flash[:alert] = '購入に失敗しました。'
        redirect_to controller: 'products', action: 'show', id: @product.id
      end
    end
  end
  # def new
  #   card = Card.where(user_id: current_user.id)
  #   redirect_to card_path(current_user.id) if card.exists?
  # end


  # def pay #payjpとCardのデータベース作成
  #   Payjp.api_key = Rails.application.credentials[:PAYJP_PRIVATE_KEY]
  #   #保管した顧客IDでpayjpから情報取得
  #   if params['payjp-token'].blank?
  #     redirect_to new_card_path
  #   else
  #     customer = Payjp::Customer.create(
  #       card: params['payjp-token'],
  #       metadata: {user_id: current_user.id}
  #     ) 
  #     @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
  #     if @card.save
  #       redirect_to card_path(current_user.id)
  #     else
  #       redirect_to pay_cards_path
  #     end
  #   end
  # end

  # def destroy #PayjpとCardデータベースを削除
  #   card = Card.find_by(user_id: current_user.id)
  #   if card.blank?
  #   else
  #     Payjp.api_key = Rails.application.credentials[:PAYJP_PRIVATE_KEY]
  #     customer = Payjp::Customer.retrieve(card.customer_id)
  #     customer.delete
  #     card.delete
  #   end
  #     redirect_to new_card_path
  # end

  # def show #Cardのデータpayjpに送り情報を取り出す
  #   card = Card.find_by(user_id: current_user.id)
  #   if card.blank?
  #     redirect_to new_card_path 
  #   else
  #     Payjp.api_key = Rails.application.credentials[:PAYJP_PRIVATE_KEY]
  #     customer = Payjp::Customer.retrieve(card.customer_id)
  #     @default_card_information = customer.cards.retrieve(card.card_id)
  #   end
  # end
end
 