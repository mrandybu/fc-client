namespace FleetCommander {
  public string?         cache_dir;
  public MainLoop?       loop;
  public ContentMonitor? monitor_singleton;

  public delegate void TestFn ();

  public static void add_test (string name, TestSuite suite, TestFn fn) {
    suite.add(new TestCase(name, setup, (GLib.TestFixtureFunc)fn, teardown));
  }

  /* Mocked Content Monitor */
  public class ContentMonitor : Object {
    public signal void content_updated ();
    public ContentMonitor (string path, uint interval = 1000) {
      monitor_singleton = this;
    }
  }

  /* setup and teardown */
  public static void setup () {
    loop = null;
    monitor_singleton = null;

    try {
      cache_dir = DirUtils.make_tmp ("fleet_commander.test.XXXXXX");
    } catch (FileError e) {
      error ("Could not create temporary dir %s", e.message);
    }
    assert_nonnull (cache_dir);
  }

  public static void teardown () {
    if (cache_dir == null)
      return;

    FileUtils.remove (cache_dir + "/profiles.json");
    DirUtils.remove (cache_dir);
    cache_dir = null;
  }

  /* Utils */
  public static void write_content (string file, string content) {
    try {
      FileUtils.set_contents (file, content);
    } catch (FileError e) {
      error ("Could not write test data in the cache file %s", e.message);
    }
  }

  /* Tests */
  public static void test_no_cache_file () {
    var cd = new CacheData (cache_dir + "/profiles.json");
    assert_nonnull (cd);

    assert (cd.get_root () == null);
    assert (cd.get_path () == cache_dir + "/profiles.json");
  }

  public static void test_existing_cache () {
    var payload = "[{ \"description\" : \"\",
                      \"settings\" : {\"org.gnome.online-accounts\" : {}, \"org.gnome.gsettings\" : []},
                      \"applies-to\" : {\"users\" : [], \"groups\" : []},
                      \"name\" : \"My profile\",
                      \"etag\" : \"placeholder\",
                      \"uid\" : \"230637306661439565351338266313693940252\"}]";
    write_content (cache_dir + "/profiles.json", payload);

    var cd = new CacheData (cache_dir + "/profiles.json");
    assert_nonnull (cd);
    assert_nonnull (cd.get_root ());
  }

  public static void test_empty_cache_file () {
    write_content (cache_dir + "/profiles.json", "");

    FcTest.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*Root JSON element*empty*");
    var cd = new CacheData (cache_dir + "/profiles.json");
    assert_nonnull (cd);
    assert (cd.get_root () == null);
  }

  public static void test_wrong_json_cache_file () {
    write_content (cache_dir + "/profiles.json", "{}");

    FcTest.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*JSON element*not an array*");
    var cd = new CacheData (cache_dir  + "/profiles.json");
    assert_nonnull (cd);
    assert (cd.get_root () == null);
  }

  public static void test_dirty_cache_file () {
    write_content (cache_dir + "/profiles.json", "#@$@#W!*");

    FcTest.expect_message (null, LogLevelFlags.LEVEL_WARNING, "*error parsing*");
    var cd = new CacheData (cache_dir  + "/profiles.json");
    assert_nonnull (cd);
    assert (cd.get_root () == null);
  }

  public static void test_content_change () {
    bool parsed_called = false;
    var payload = "[{ \"description\" : \"\",
                      \"settings\" : {\"org.gnome.online-accounts\" : {}, \"org.gnome.gsettings\" : []},
                      \"applies-to\" : {\"users\" : [], \"groups\" : []},
                      \"name\" : \"My profile\",
                      \"etag\" : \"placeholder\",
                      \"uid\" : \"230637306661439565351338266313693940252\"}]";
    write_content (cache_dir + "/profiles.json", payload);

    loop = new MainLoop (null, false);

    var cd = new CacheData (cache_dir  + "/profiles.json");
    assert_nonnull (cd);
    assert_nonnull (cd.get_root ());

    FileUtils.remove (cache_dir + "/profiles.json");

    Idle.add (() => {
      assert_nonnull (monitor_singleton);
      //simulate a file monitor signal
      monitor_singleton.content_updated ();
      loop.quit ();
      loop = null;
      return false;
    });

    loop.run();
    assert (cd.get_root () == null);
  }

  public static int main (string[] args) {
    Test.init (ref args);
    var fc_suite = new TestSuite("fleetcommander");
    var pcm_suite = new TestSuite("cache-data");

    add_test ("no-cache", pcm_suite, test_no_cache_file);
    add_test ("existing-cache", pcm_suite, test_existing_cache);
    add_test ("empty-cache-file", pcm_suite, test_empty_cache_file);
    add_test ("dirty-cache", pcm_suite, test_dirty_cache_file);
    add_test ("content-change", pcm_suite, test_content_change);
    //TODO: removed existing cache

    fc_suite.add_suite (pcm_suite);
    TestSuite.get_root ().add_suite (fc_suite);
    return Test.run();
  }
}
