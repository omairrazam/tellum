if @notification.present?
  @notification.update_attribute :is_seen, true
  json.status 'Ok'
  json.code 200
  json.notification_id @notification.try(:id)
  json.message 'Notification Read Successfully.'
else
  json.status 'not found'
  json.code 501
  json.message "Invalid Request"
end