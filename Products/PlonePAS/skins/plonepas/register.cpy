## Controller Python Script "register"
##bind container=container
##bind context=context
##bind namespace=
##bind script=script
##bind state=state
##bind subpath=traverse_subpath
##parameters=password='password', password_confirm='password_confirm', came_from_prefs=None
##title=Register a User
##

# CHANGE NOTES: changing 'came_from' so that we don't loop 'logged_in' twice
#               (since PAS cookie auth is no longer implicit)
#               this could probably be moved upstream to Plone

from ZODB.POSException import ConflictError

REQUEST=context.REQUEST

portal_registration=context.portal_registration
site_properties=context.portal_properties.site_properties

username = REQUEST['username']

password=REQUEST.get('password') or portal_registration.generatePassword()

# This is a temporary work-around for an issue with CMF not properly
# reserving some existing ids (FSDV skin elements, for example). Until 
# this is fixed in the CMF we can at least fail nicely. See
# http://plone.org/collector/2982 and http://plone.org/collector/3028
# for more info. (rohrer 2004-10-24)
try:
    portal_registration.addMember(username, password, properties=REQUEST)
except AttributeError:
    state.setError('username', 'The login name you selected is already in use or is not valid. Please choose another.')
    return state.set(status='failure', portal_status_message='Please correct the indicated errors.')

if site_properties.validate_email or REQUEST.get('mail_me', 0):
    try:
        portal_registration.registeredNotify(username)
    except ConflictError:
        raise
    except Exception, err: 

        #XXX registerdNotify calls into various levels.  Lets catch all exceptions.
        #    Should not fail.  They cant CHANGE their password ;-)  We should notify them.
        #
        # (MSL 12/28/03) We also need to delete the just made member and return to the join_form.
               
        state.setError('email', 'We were unable to send your password to your email address: '+str(err))
        state.set(came_from='login_success')
        context.acl_users.userFolderDelUsers([username,])
        return state.set(status='failure', portal_status_message='Please enter a valid email address.')
        
state.set(portal_status_message=REQUEST.get('portal_status_message', 'Registered.'))
state.set(came_from=REQUEST.get('came_from','login_success'))

if came_from_prefs:
    state.set(status='prefs', portal_status_message='User added.')

from Products.CMFPlone import transaction_note
transaction_note('%s registered' % username)

return state
