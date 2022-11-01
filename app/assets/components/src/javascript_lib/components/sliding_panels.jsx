import React from 'react';
import PropTypes from 'prop-types';
import shortid from 'shortid';

import applyComponentDecorators from 'javascript_lib/utils/apply_component_decorators';

import slidingPanelsStyle from 'javascript_lib/styles/sliding_panels.style';
import 'javascript_lib/styles/sliding_panels.scss';


class SlidingPanels extends React.Component {

  constructor(props) {
    super(props);
  }

  _renderPanel(panel) {
    return(
      <div
        key={shortid.generate()}
        className="sliding-panels__panel"
        style={slidingPanelsStyle.panel(this.props.panels.length)}
      >
        {this.props.panelRenderer(panel)}
      </div>
    );
  }

  _renderPanels() {
    return this.props.panels.map(panel => {
      return this._renderPanel(panel);
    });
  }

  render() {
    return(
      <div className="sliding-panels">
        <div
          className="sliding-panels__panels-container"
          style={slidingPanelsStyle.panelsContainer(this.props.panels.length, this.props.panelIndex)}
        >
          {this._renderPanels()}
        </div>
      </div>
    );
  }
}

SlidingPanels.propTypes = {
  panelRenderer: PropTypes.func,
  panels: PropTypes.array,
  panelIndex: PropTypes.number
};

SlidingPanels.defaultProps = {
  panelRenderer: null,
  panels: [],
  panelIndex: 0
};

export default applyComponentDecorators(SlidingPanels);
