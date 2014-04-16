/*
 * Copyright (C) 2014 Red Hat, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the licence, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 *
 * Author: Matthew Barnes <mbarnes@redhat.com>
 */

#ifndef __FCMDR_PROFILE_H__
#define __FCMDR_PROFILE_H__

#include <gio/gio.h>

/* Standard GObject macros */
#define FCMDR_TYPE_PROFILE \
	(fcmdr_profile_get_type ())
#define FCMDR_PROFILE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), FCMDR_TYPE_PROFILE, FCmdrProfile))
#define FCMDR_PROFILE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), FCMDR_TYPE_PROFILE, FCmdrProfileClass))
#define FCMDR_IS_PROFILE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), FCMDR_TYPE_PROFILE))
#define FCMDR_IS_PROFILE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), FCMDR_TYPE_PROFILE))
#define FCMDR_PROFILE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), FCMDR_TYPE_PROFILE, FCmdrProfileClass))

G_BEGIN_DECLS

typedef struct _FCmdrProfile FCmdrProfile;
typedef struct _FCmdrProfileClass FCmdrProfileClass;
typedef struct _FCmdrProfilePrivate FCmdrProfilePrivate;

struct _FCmdrProfile {
	GObject parent;
	FCmdrProfilePrivate *priv;
};

struct _FCmdrProfileClass {
	GObjectClass parent_class;
};

GType		fcmdr_profile_get_type		(void) G_GNUC_CONST;
FCmdrProfile *	fcmdr_profile_load_sync		(GInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
void		fcmdr_profile_load		(GInputStream *stream,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
FCmdrProfile *	fcmdr_profile_load_finish	(GAsyncResult *result,
						 GError **error);
guint		fcmdr_profile_hash		(FCmdrProfile *profile);
gboolean	fcmdr_profile_equal		(FCmdrProfile *profile1,
						 FCmdrProfile *profile2);
const gchar *	fcmdr_profile_get_uid		(FCmdrProfile *profile);
gchar *		fcmdr_profile_to_data		(FCmdrProfile *profile,
						 gboolean pretty_print,
						 gsize *length);

G_END_DECLS

#endif /* __FCMDR_PROFILE_H__ */
