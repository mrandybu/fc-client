namespace FleetCommander {
  public class ConfigurationAdapterGOA : ConfigurationAdapter, Object {
    const string FC_ACCOUNTS_FILE = "fleet-commander-accounts.conf";
    string goa_runtime_path;
    public ConfigurationAdapterGOA (string goa_runtime_path) {
      this.goa_runtime_path = goa_runtime_path;
    }

    public void bootstrap (UserIndex index, CacheData profiles_cache, Logind.User[] users) {
      try {
        rmrf (goa_runtime_path);
      } catch (Error e) {
        warning ("There was a problem trying to wipe %s: %s", goa_runtime_path, e.message);
      }
      foreach (var user in users) {
        update (index, profiles_cache, user.uid);
      }
    }

    public void update (UserIndex index, CacheData profiles_cache, uint32 uid) {
      debug ("Updating GOA profile for user %u", uid);
      try {
        create_goa_runtime_path (uid);
      } catch (Error e) {
        warning ("Could not create goa path for user: %s", e.message);
        return;
      }

      var name = Posix.uid_to_user_name (uid);
      var groups = Posix.get_groups_for_user (uid);

      var profile_uids = index.get_profiles_for_user_and_groups (name, groups);

      if (profile_uids.length < 1) {
        debug ("User %u did not have any profiles assigned", uid);
        return;
      }

      var profiles = profiles_cache.get_profiles (profile_uids);

      if (profiles == null || profiles.length != profile_uids.length) {
        string uids = "";
        foreach (var u in profile_uids) {
          uids = "%s, %s".printf (uids, u);
        }

        debug ("Could not find indexed uids in profiles cache: %s", uids);

        if (profiles == null)
          return;
      }

      var keyfile = new KeyFile ();
      foreach (var profile in profiles) {
        var settings = profile.get_object_member("settings");
        if (settings == null)
          continue;

        //TODO: Wait for discussion with oliver on using a list here
        var goa = settings.get_object_member ("org.gnome.online-accounts");
        if (goa == null)
          continue;

        goa.foreach_member ((o, account_name, account_node) => {
          var account = account_node.get_object ();
          if (account == null)
            return;

          account.foreach_member ((ao, key, value_node) => {
            if (value_node.get_node_type () != Json.NodeType.VALUE) {
              warning ("Key %s on provider %s did not hold a valid value", key, account_name);
              return;
            }

            string? val = null;
            //TODO: Explore if we need to support more data types
            if (value_node.get_value_type () == typeof(string)) {
              val = value_node.get_string ();
            } else if (value_node.get_value_type () == typeof(bool)) {
              val = value_node.get_boolean ()? "true" : "false";
            } else {
              warning ("Value type for key %s/%s not supported", account_name, key);
              return;
            }

            if (val == null) {
              warning ("Could not assign string to %s/%s", account_name, key);
              return;
            }

            keyfile.set_string (account_name, key, val);
          });
        });
      }

      try {
        keyfile.save_to_file ("%s/%u/%s".printf (goa_runtime_path, uid, FC_ACCOUNTS_FILE));
      } catch (Error e) {
        warning ("There was an error saving GOA account file %s", e.message);
      }
    }

    public void create_goa_runtime_path (uint32 uid) throws Error {
      var uid_path = "%s/%u".printf(goa_runtime_path, uid);
      if (FileUtils.test (uid_path, FileTest.EXISTS) == false) {
        if (DirUtils.create_with_parents (uid_path, 0755) != 0)
          throw new FCError.ERROR ("Could not create directory %s with parents.".printf(uid_path));
      }

      var accounts = "%s/fleet-commander-accounts.conf".printf(uid_path);
      if (FileUtils.test (accounts, FileTest.EXISTS) == false)
        return;

      if (FileUtils.remove(accounts) != 0)
        throw new FCError.ERROR ("Could not remove file %s", accounts);
    }
  }
}
