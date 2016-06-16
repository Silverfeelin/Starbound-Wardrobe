using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WardrobeItemFetcher
{
    class Program
    {
        /// <summary>
        /// File callback for <see cref="ScanDirectory(DirectoryInfo, bool, FileCallback)"/>
        /// </summary>
        /// <param name="file">File information for the found file.</param>
        delegate void FileCallback(FileInfo file);

        /// <summary>
        /// All item extensions to parse.
        /// </summary>
        static string[] extensions = new string[]
        {
            "head",
            "chest",
            "legs",
            "back"
        };

        /// <summary>
        /// Result.
        /// Contains 4 arrays representing categories, which contain the items of said categories.
        /// Written to text file after fetching items.
        /// </summary>
        static JObject result;

        /// <summary>
        /// Base path. Used to create the absolute asset path.
        /// </summary>
        static string basePath;
        static string itemPath;

        enum WriteMethod
        {
            Overwrite,
            Merge
        }
        /// <summary>
        /// Startup method. Scans the given directory and all subdirectories for item files.
        /// Adds all information necessary for the Wardrobe mod and writes it to the given output file.
        /// </summary>
        /// <param name="args">Unpacked asset path and output file path.</param>
        static void Main(string[] args)
        {
            if (args.Length != 2 || !Directory.Exists(args[0]))
            {
                Console.WriteLine("Improper usage. Expected: <asset_path> <output_file>\nAsset path: Absolute path to unpacked assets. Do not end the path with a \\. \nOutput file: Absolute path to file to write results to\nPress any key to exit...");
                Console.ReadKey();
                return;
            }
            else if (!Directory.Exists(args[0] + @"\items"))
            {
                Console.WriteLine("Subdirectory '\\items' not found. Invalid directory given.\nPress any key to exit...");
                Console.ReadKey();
                return;
            }

            WriteMethod writeMethod = WriteMethod.Overwrite;

            if (File.Exists(args[1]))
            {
                Console.WriteLine("Output file already exists!\n1. Overwrite file\n2. Merge content (prioritizes new items)\n3. Cancel");

                ConsoleKeyInfo cki = Console.ReadKey(true);
                switch (cki.Key)
                {
                    default:
                        Console.WriteLine("Cancelling task.\nPress any key to exit...");
                        Console.ReadKey();
                        return;
                    case ConsoleKey.D1:
                    case ConsoleKey.NumPad1:
                        Console.WriteLine("File will be overwritten.");
                        break;
                    case ConsoleKey.D2:
                    case ConsoleKey.NumPad2:
                        Console.WriteLine("Content will be merged.");
                        writeMethod = WriteMethod.Merge;
                        break;
                }
            }

            basePath = args[0];
            itemPath = basePath + @"\items".Replace(@"\\", @"\");

            DirectoryInfo rootDirectory = new DirectoryInfo(itemPath);

            result = new JObject();
            result["head"] = new JArray();
            result["chest"] = new JArray();
            result["legs"] = new JArray();
            result["back"] = new JArray();

            FileCallback fc = new FileCallback(AddItem);

            ScanDirectory(rootDirectory, true, fc);

            Console.WriteLine("Results:");
            Console.WriteLine("- Head: " + result["head"].Count() + " items.");
            Console.WriteLine("- Chest: " + result["chest"].Count() + " items.");
            Console.WriteLine("- Legs: " + result["legs"].Count() + " items.");
            Console.WriteLine("- Back: " + result["back"].Count() + " items.");

            switch (writeMethod)
            {
                case WriteMethod.Merge:
                    JObject original = JObject.Parse(File.ReadAllText(args[1]));
                    result.Merge(original, new JsonMergeSettings() { MergeArrayHandling = MergeArrayHandling.Union });
                    break;
                default:
                    break;
            }

            File.WriteAllText(args[1], result.ToString(Formatting.None));

            Console.WriteLine("Done fetching items!\nPress any key to exit...");
            Console.ReadKey();
        }

        /// <summary>
        /// Scans the directory and optionally all subdirectories, running the callback for each found file matching an extension in <see cref="extensions"/>.
        /// </summary>
        /// <param name="dir">Directory to scan for matching files.</param>
        /// <param name="recursive">Value indicating whether to check directories recursively or not.</param>
        /// <param name="callback">Callback for each found file.</param>
        static void ScanDirectory(DirectoryInfo dir, bool recursive, FileCallback callback)
        {
            Console.WriteLine("Scanning '" + dir.FullName + "'");

            FileInfo[] files = dir.GetFiles("*.*");
            files = files.Where(f => extensions.Contains(f.Extension.Replace(".", ""))).ToArray();

            foreach (FileInfo file in files)
            {
                callback(file);
            }

            if (recursive)
            {
                DirectoryInfo[] directories = dir.GetDirectories();
                foreach (var item in directories)
                {
                    ScanDirectory(item, true, callback);
                }
            }
        }

        /// <summary>
        /// Callback that scans the item file and adds the information needed for the Wardrobe mod to <see cref="result"/>.
        /// </summary>
        /// <param name="file">File to scan. Expected to be a JSON formatted item file.</param>
        static void AddItem(FileInfo file)
        {
            string content = File.ReadAllText(file.FullName);
            JObject item = null;
            try
            {
                item = JObject.Parse(content);
            }
            catch (Exception exc)
            {
                Console.WriteLine("Skipped '" + file.FullName + "', as it could not be parsed as a valid JSON file.");
            }

            JObject newItem = new JObject();
            newItem["name"] = item["itemName"];
            newItem["shortdescription"] = item["shortdescription"];
            string category = file.Extension.Replace(".", "");
            newItem["category"] = category;
            // Base path removed to get an asset path. Slash added to the end and backslashes converted to regular slashes.
            newItem["path"] = (Path.GetDirectoryName(file.FullName) + "/").Replace(basePath, "").Replace("\\", "/");
            newItem["icon"] = item["inventoryIcon"];
            newItem["fileName"] = file.Name;
            newItem["maleFrames"] = item["maleFrames"];
            newItem["femaleFrames"] = item["femaleFrames"];
            newItem["mask"] = item["mask"];
            newItem["rarity"] = item["rarity"].Value<string>().ToLower();
            JToken colorOptions = item.SelectToken("colorOptions");
            if (colorOptions is JArray)
            {
                newItem["colorOptions"] = colorOptions;
            }

            ((JArray)result[category]).Add(newItem);
        }
    }
}
