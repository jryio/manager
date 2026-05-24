# Health Check

To ensure your Helix installation is configured correctly, run:

```
hx --health
```

The output is divided into two sections:

## 1. Helix Configuration Section

![health_config](https://github.com/user-attachments/assets/df2660fb-0ab7-4457-8b02-32fbba962ef1)


The first section displays the locations of key files currently used by Helix, including:

- The configuration file
- The language file
- The log file
- The runtime directories
- The system clipboard provider (if available)

## 2. Language Configuration Section

![image](https://github.com/user-attachments/assets/7ef07088-8a3f-409f-bba3-fb68ac952b4b)


The second section presents a table showing the status of each supported language. Each language has several configurable features:

- Language servers
- Debug adapter
- Formatter
- Syntax highlighting
- Text object (e.g., jump to functions, classes; [details here](https://docs.helix-editor.com/guides/textobject.html))
- Indentation ([details here](https://docs.helix-editor.com/master/guides/indent.html))

Table entry colors indicate feature status:
- <b style="color:red">Red</b>: Feature not found on the system
- <b style="color:yellow">Yellow</b>: Feature not configured
- <b style="color:green">Green</b>: Feature found and configured

For detailed language-specific information, run:

```
hx --health [LANG]
```

This provides additional details beyond the features listed above, including:
- Location of the LSP binary (if available)
- Location of the DAP binary (if available)

