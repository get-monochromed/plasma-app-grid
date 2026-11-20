/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2013-2015 Eike Hein <hein@kde.org>
    SPDX-FileCopyrightText: 2017 Ivan Cukic <ivan.cukic@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

.pragma library

function actionsFor(translate, actionList, favoriteModel, favoriteId) {
    const actions = Array.from(actionList ?? []);
    const favourites = createFavoriteActions(translate, favoriteModel, favoriteId);
    if (!favourites) {
        return actions;
    }
    if (!actions.length) {
        return favourites;
    }

    const launcherActions = ["addToDesktop", "addToTaskManager", "addToPanel"];
    const firstLauncherAction = actions.findIndex(action => launcherActions.includes(action.actionId));
    if (firstLauncherAction >= 0) {
        actions.splice(firstLauncherAction, 0, ...favourites);
    } else {
        actions.push({ type: "separator" }, ...favourites);
    }
    return actions;
}

function createFavoriteActions(translate, favoriteModel, favoriteId) {
    if (!favoriteModel || !favoriteModel.enabled || !favoriteId) {
        return null;
    }

    if (favoriteModel.activities === undefined ||
        favoriteModel.activities.activities.length <= 1) {
        const action = {};

        if (favoriteModel.isFavorite(favoriteId)) {
            action.text = translate("Remove from Favourites");
            action.icon = "bookmark-remove";
            action.actionId = "_kicker_favorite_remove";
        } else if (favoriteModel.maxFavorites === -1 || favoriteModel.count < favoriteModel.maxFavorites) {
            action.text = translate("Add to Favourites");
            action.icon = "bookmark-new";
            action.actionId = "_kicker_favorite_add";
        } else {
            return null;
        }

        action.actionArgument = {
            favoriteModel,
            favoriteId,
        };

        return [action];

    } else {
        const actions = [];

        const linkedActivities = favoriteModel.linkedActivitiesFor(favoriteId);

        const activities = favoriteModel.activities.activities;
        // Adding the item to link/unlink to all activities

        const linkedToAllActivities = linkedActivities.includes(":global");

        actions.push({
            text: translate("On All Activities"),
            checkable: true,

            actionId: linkedToAllActivities
                ? "_kicker_favorite_remove_from_activity"
                : "_kicker_favorite_set_to_activity",

            checked: linkedToAllActivities,

            actionArgument: {
                favoriteModel,
                favoriteId,
                favoriteActivity: "",
            },
        });

        // Adding items for each activity separately

        const addActivityItem = (activityId, activityName) => {
            const linkedToThisActivity = linkedActivities.includes(activityId);

            actions.push({
                text: activityName,
                checkable: true,
                checked: linkedToThisActivity && !linkedToAllActivities,

                actionId:
                    // If we are on all activities, and the user clicks just one
                    // specific activity, unlink from everything else
                    linkedToAllActivities ? "_kicker_favorite_set_to_activity" :

                    // If we are linked to the current activity, just unlink from
                    // that single one
                    linkedToThisActivity ? "_kicker_favorite_remove_from_activity" :

                    // Otherwise, link to this activity, but do not unlink from
                    // other ones
                    "_kicker_favorite_add_to_activity",

                actionArgument: {
                    favoriteModel,
                    favoriteId,
                    favoriteActivity: activityId,
                },
            });
        };
        // Adding the item to link/unlink to the current activity

        addActivityItem(favoriteModel.activities.currentActivity, translate("On the Current Activity"));

        actions.push({
            type: "separator",
            actionId: "_kicker_favorite_separator",
        });
        // Adding the items for each activity

        activities.forEach(activityId => {
            addActivityItem(activityId, favoriteModel.activityNameForId(activityId));
        });

        return [{
            text: translate("Show in Favourites"),
            icon: "favorite",
            subActions: actions,
        }];
    }
}

function handleFavoriteAction(actionId, actionArgument) {
    const { favoriteId, favoriteModel, favoriteActivity } = actionArgument;

    if (!favoriteModel || !favoriteId) {
        return;
    }

    if (actionId === "_kicker_favorite_remove") {
        favoriteModel.removeFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_add") {
        favoriteModel.addFavorite(favoriteId);
    } else if (actionId === "_kicker_favorite_remove_from_activity") {
        favoriteModel.removeFavoriteFrom(favoriteId, favoriteActivity);
    } else if (actionId === "_kicker_favorite_add_to_activity") {
        favoriteModel.addFavoriteTo(favoriteId, favoriteActivity);
    } else if (actionId === "_kicker_favorite_set_to_activity") {
        favoriteModel.setFavoriteOn(favoriteId, favoriteActivity);
    }
}
