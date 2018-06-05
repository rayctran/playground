<?php
/***********************************************************************
 * settings.php - Example File
 *
 * Explains the variables that can be used in a custom settings.php
 *
 **********************************************************************/

/***********************************************************************
 * $ShowBranchesDialogBox
 *
 * To show the branches control tab, set to true, false=hide
 * acceptable values = true and false
 * default: false
 **********************************************************************/
$ShowBranchesDialogBox = true;

/***********************************************************************
 * $ShowBranchesAsDropdown
 *
 * Controls how the selection for branches is presented to the user.
 * -- true = show as a dropdown, false = show as radio buttons
 * acceptable values = true and false
 * default: true
 **********************************************************************/
$ShowBranchesAsDropdown = true;

/***********************************************************************
 * $ShowTagsAsDropdown
 *
 * Controls how the selection for tags is presented to the user.
 * -- true = show as a dropdown, false = show as radio buttons
 * acceptable values = true and false
 * default: true
 **********************************************************************/
$ShowTagsAsDropdown = true;

/***********************************************************************
 * $ShowBranchesFirst
 *
 * Controls which tab is active upon initial load.  This is useful in
 * environments (such as stage) where you would not be deploying tags,
 * but rather branches.
 * -- true = branches tab active, false = tags tab active
 * acceptable values = true and false
 * default: false
 **********************************************************************/
$ShowBranchesFirst = false;

/**********************************************************************
 * $EmailDeploymentRollback
 *
 * Emails deployment and rollback details to those in the email list
 *
 * acceptable values = true and false
 * default: true
 *
 * *********************************************************************/
$EmailDeploymentRollback = true;

/**********************************************************************
 * $ShowDBBackupDialog
 *
 * Show the dialog box to allow db dumps.
 *
 * acceptable values = true and false
 * default: false
 *
 * *********************************************************************/
$ShowDBBackupDialog = false;

/**********************************************************************
 * $SelfUpgrade
 *
 * Allows the dashboard to automatically upgrade itself to the latest TAG.
 *
 * acceptable values = true and false
 * default: false
 *
 * *********************************************************************/
$SelfUpgrade = false;

/**********************************************************************
 * $wormlyAPIkey
 *
 * Wormly API Key. Allows the dashboard to get the status
 * of the sensor for a particular client.
 * 
 * acceptable value = text string (key from Wormly API)
 * default: hheeO1eSVOGrZDtmtKWxiejrY2PcQpO4
 *
 * *********************************************************************/
$wormlyAPIkey = 'hheeO1eSVOGrZDtmtKWxiejrY2PcQpO4';

/**********************************************************************
 * $wormlyClientID
 *
 * Wormly Client ID. This is the hostid (number) of the client
 * in the wormly interface. Generally 5 digits or longer
 * 
 * acceptable value = client id
 * default: NULL
 *
 * *********************************************************************/
$wormlyClientID = '';

/**********************************************************************
 * $WebUser
 *
 * The web user. Some times called 'apache' (CentOS) or 
 * 'www-data' (Ubuntu)
 * 
 * 
 * default: apache
 *
 * *********************************************************************/
$WebUser = 'www-data';
 
?>
