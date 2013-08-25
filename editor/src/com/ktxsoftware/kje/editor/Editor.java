package com.ktxsoftware.kje.editor;

import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.BoxLayout;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.UIManager;

public class Editor extends JFrame{
	private static final long serialVersionUID = 1L;

	public Editor() {
		super("Editor");
		try {
			UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		}
		catch (Exception e) {
			e.printStackTrace();
		}
		setDefaultLookAndFeelDecorated(true);
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		setMinimumSize(new Dimension(1000, 600));
		
		JMenuBar menuBar = new JMenuBar();
		setJMenuBar(menuBar);
		JMenu file = new JMenu("File");
		JMenuItem newLevel = new JMenuItem("New");
		JMenuItem loadLevel = new JMenuItem("Load");
		JMenuItem saveLevel = new JMenuItem("Save");
		JMenuItem resizeLevel = new JMenuItem("Resize");
		
		loadLevel.addActionListener(new Loader(this));
		saveLevel.addActionListener(new Saver(this));
		newLevel.addActionListener(new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent e) {
				Level.getInstance().resetMaps();
			}
		});
		resizeLevel.addActionListener(new ActionListener() {
			@Override
			public void actionPerformed(ActionEvent e) {
				new ResizeDialog(Editor.this);
			}
		});

		file.add(newLevel);
		file.add(loadLevel);
		file.add(saveLevel);
		file.add(resizeLevel);

		menuBar.add(file);
		
		JPanel main = new JPanel();
		main.setLayout(new BoxLayout(main, BoxLayout.Y_AXIS));
		
		JScrollPane levelScrollPane = new JScrollPane(Level.getInstance());
		levelScrollPane.setPreferredSize(new Dimension(1000, 600));
		main.add(levelScrollPane);
		
		JPanel bottom = new JPanel();
		bottom.setLayout(new BoxLayout(bottom, BoxLayout.X_AXIS));
		
		JScrollPane tilesScrollPane = new JScrollPane(TilesetPanel.getInstance());
		JScrollPane spritesScrollPane = new JScrollPane(SpritesPanel.getInstance());
		
		bottom.add(tilesScrollPane);
		bottom.add(spritesScrollPane);
		
		main.add(bottom);
		add(main);
		
		pack();
		setSize(1280, 720);
		setVisible(true);
	}

	public static void main(String[] args) {
		javax.swing.SwingUtilities.invokeLater(
			new Runnable() {
				public void run() {
					new Editor();
				}
			}
		);
	}
}